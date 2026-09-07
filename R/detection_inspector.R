# detection_inspector.R ------------------------------------------------------
# The machinery both detection maps are built on
#
# explore_s1_detections() and explore_s2_detections() are the same map over two
# sensors: one marker per detection, a popup carrying the crop the detection was
# made from, and an exported copy with a contact sheet beside it. Everything in
# that sentence that does not depend on which satellite took the picture lives
# here, so neither sibling has to borrow from the other.
#
#   - ee_connect(): the Earth Engine connection crops are rendered through.
#     Exported because it is worth opening once per session, and because its
#     workarounds are the whole reason rgee is usable from a knitr chunk at all
#   - psd_crop_sources(): the cache. Both sensors land on 10 m pixels and file
#     their crops under the same names, so only the thumbnail builder differs
#   - psd_inspector_css() / psd_inspector_js(): the popup card and the crop
#     viewer, which arrow keys step through
#   - psd_gallery_js(): the second pane, added to the exported page only
#
# Internal helpers (not exported): quiet_deprecated_assets(), first_col(),
# trunc_middle(), psd_thumb_path(), ensure_pandoc(). The satellite chrome and the title-banner
# export come from map_utils.R, so these maps look like every other Pristine
# Seas map.
#
# On caching, which is what makes a map worth exporting: `getThumbURL()` hands
# back a rendered resource, not a permanent link, and it dies within days. So the
# crops are downloaded once into `cache_dir` and inlined as `data:` URIs. Nothing
# in the exported HTML can expire, a cached crop never costs a second Earth
# Engine round-trip, and a caller whose crops are all cached needs no Earth
# Engine credentials at all.
#
# The `psd-` prefix on every class name marks this shared surface: the CSS, the
# popup markup and the two hooks all speak it, and a sensor that writes its own
# popup writes `psd-` too.

# Session state, so a second map in the same document does not pay for the
# Earth Engine handshake twice
.ee_state <- new.env(parent = emptyenv())

# Silence the Earth Engine client's roll-call of deprecated assets.
#
# On initialisation `ee` walks the public catalog and warns about every retired
# asset in it — dozens of them, none anything this package touches. A plain
# `filterwarnings("ignore")` does not stop them: `ee` installs its own "default"
# filter for the module, and Python prepends filters, so whichever is set last
# wins. Neutering that call is what makes the filter hold, and it also restores
# Python's own default, which is to keep DeprecationWarning quiet outside
# `__main__`. Wrapped in `try()` so a missing client still fails where it should,
# in `ee_Initialize()`, with a message that says so.
quiet_deprecated_assets <- function() {
  try(
    reticulate::py_run_string(paste(
      "import warnings, ee.deprecation as d",
      "d._UnfilterDeprecationWarnings = lambda: None",
      "warnings.filterwarnings('ignore', category=DeprecationWarning,",
      "                        module=r'ee\\.deprecation')",
      sep = "\n")),
    silent = TRUE)
  invisible(NULL)
}

#' Connect to Google Earth Engine
#'
#' @description
#' Opens the `rgee` connection that [explore_s1_detections()] and
#' [explore_s2_detections()] render their crops through, working around two
#' things that otherwise make `rgee` unusable from a knitr chunk:
#'
#' * `rgee` asks Earth Engine for the account's legacy asset root, but the
#'   `earthengine-api` no longer answers that call — it returns nothing whether
#'   or not a home exists. `rgee` then prompts for a folder name, and
#'   `readline()` returns `""` instantly in a non-interactive chunk, so the
#'   prompt loops on an answer it will never get. Supplying `asset_home` skips
#'   the lookup entirely.
#' * `reticulate` does not read `EARTHENGINE_PYTHON` — that variable is `rgee`'s
#'   — and defaults to its own managed environment, which has no
#'   `earthengine-api`. `rgee` then reports the interpreter it *wanted* rather
#'   than the one in use, so the error names a Python that does have the package.
#'   Binding the interpreter before `rgee` touches Python at all avoids it.
#'
#' Calling this more than once in a session is free: the connection is opened on
#' the first call and remembered.
#'
#' @param project Earth Engine cloud project to bill and authenticate against,
#'   e.g. `"pristine-seas"`.
#' @param python Path to a Python interpreter that has `earthengine-api`
#'   installed. Defaults to the `EARTHENGINE_PYTHON` environment variable; pass
#'   `""` to leave `reticulate`'s own choice alone.
#' @param asset_home The account's Earth Engine asset root, e.g.
#'   `"users/jsmith"`. Optional, and only needed if `rgee` stalls on the asset
#'   root prompt described above.
#' @param force Re-open the connection even if one was already made this
#'   session. Default `FALSE`.
#'
#' @return `TRUE`, invisibly.
#'
#' @examples
#' \dontrun{
#' ee_connect(project = "pristine-seas", asset_home = "users/jsmith")
#' }
#'
#' @export
ee_connect <- function(project,
                       python     = Sys.getenv("EARTHENGINE_PYTHON"),
                       asset_home = NULL,
                       force      = FALSE) {

  if (!force && isTRUE(.ee_state$connected)) return(invisible(TRUE))

  if (missing(project) || is.null(project) || !nzchar(project)) {
    stop("`project` is required: the Earth Engine cloud project to authenticate ",
         "against, e.g. \"pristine-seas\".", call. = FALSE)
  }

  rlang::check_installed(c("rgee", "reticulate"),
                         "to render Sentinel-2 crops from Earth Engine.")

  if (!is.null(python) && nzchar(python)) {
    reticulate::use_python(python, required = TRUE)
  }

  # Deliberate: there is no supported way to tell rgee the asset root, and the
  # lookup it does instead cannot succeed. R CMD check notes this call.
  if (!is.null(asset_home)) {
    utils::assignInNamespace("ee_check_root_folder", function() asset_home, ns = "rgee")
  }

  quiet_deprecated_assets()

  rgee::ee_Initialize(project = project, quiet = TRUE)

  .ee_state$connected <- TRUE
  invisible(TRUE)
}

# The first of `names` the table actually carries, or NULL. Both sensors take
# their optional columns under more than one name — GFW files radar lengths under
# `length_m` and optical under `length_m_inferred`, and a table assembled by hand
# agrees with neither — so asking for a list beats asking for one.
first_col <- function(df, names) {
  hit <- intersect(names, base::names(df))
  if (length(hit) > 0) df[[hit[[1]]]] else NULL
}

# Middle-truncate an identifier: a detection id is its scene plus its position,
# so both ends carry information and only the middle is safe to drop
trunc_middle <- function(x, width) {
  ifelse(nchar(x) <= width, x,
         paste0(substr(x, 1, ceiling((width - 1) / 2)), "…",
                substr(x, nchar(x) - floor((width - 1) / 2) + 1, nchar(x))))
}

# Where a detection's crop lives. `detect_id` is the scene id with the position
# appended, so the name is unique by construction and traces back to its row
psd_thumb_path <- function(detect_id, cache_dir, buffer_m, px, view) {
  file.path(cache_dir,
            paste0(gsub("[^A-Za-z0-9._-]", "_", detect_id),
                   "_", buffer_m, "m_", px, "px_", view, ".png"))
}

# The crop for every row, as something an <img> can use.
#
# Asking Earth Engine for a bigger thumbnail than the sensor holds buys nothing:
# it upsamples nearest-neighbour, so a 600-pixel crop of a 1 km window is the
# same hundred pixels drawn six times over, at half again the bytes. The browser
# does that upsampling itself (`image-rendering: pixelated` in the CSS), so the
# crop is pulled at native scale and blown up on arrival.
#
# `thumb_url` is the sensor's own builder and `labels` names its views; both
# sensors are 10 m a pixel, so nothing else about the cache differs between them.
psd_crop_sources <- function(df, cache_dir, buffer_m, view, embed, connect,
                             thumb_url, labels) {

  px        <- as.integer(ceiling(2 * buffer_m / 10))
  connected <- FALSE
  offline   <- FALSE

  # Deferred, so a run whose cache is complete never opens Earth Engine at all —
  # which is what lets a colleague rebuild the map with no credentials.
  #
  # A crop the archive does not hold already degrades to a marker without a
  # picture. An Earth Engine that cannot be reached — no credentials, expired
  # ones, no network — is the same failure at a different layer, so it takes the
  # same path rather than killing the map. The warning says so once, and a later
  # run with working credentials fills the cache in.
  once <- function() {
    if (offline)   return(invisible(FALSE))
    if (connected) return(invisible(TRUE))
    ok <- tryCatch({ connect(); TRUE },
                   error = function(e) {
                     warning("Earth Engine unavailable, so detections are drawn without crops: ",
                             conditionMessage(e), call. = FALSE)
                     FALSE
                   })
    connected <<- ok
    offline   <<- !ok
    invisible(ok)
  }

  pull <- function(i, v) {
    vapply(i, function(k) thumb_url(df$scene_id[k], df$detect_lon[k], df$detect_lat[k],
                                    buffer_m = buffer_m, px = px, view = v),
           character(1))
  }

  one_view <- function(v) {

    if (!embed) {
      # Nothing to cache: these expire, so they are always pulled fresh
      if (!once()) return(rep(NA_character_, nrow(df)))
      return(pull(seq_len(nrow(df)), v))
    }

    path <- psd_thumb_path(df$detect_id, cache_dir, buffer_m, px, v)
    need <- which(!file.exists(path))

    if (length(need) > 0 && once()) {
      cli::cli_inform(c("i" = "Rendering {length(need)} {labels[[v]]}
                               {cli::qty(length(need))}crop{?s} — about a second each.
                               Cached in {.path {cache_dir}}."))
      urls       <- rep(NA_character_, nrow(df))
      urls[need] <- pull(need, v)
      for (k in need) {
        if (!is.na(urls[k])) {
          try(utils::download.file(urls[k], path[k], quiet = TRUE, mode = "wb"), silent = TRUE)
        }
      }
    }

    ok  <- file.exists(path)
    src <- rep(NA_character_, nrow(df))
    src[ok] <- vapply(path[ok], function(f) {
      paste0("data:image/png;base64,",
             gsub("[\r\n]", "", jsonlite::base64_enc(readBin(f, "raw", file.size(f)))))
    }, character(1), USE.NAMES = FALSE)

    src
  }

  if (embed) dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  out <- lapply(view, one_view)
  names(out) <- view
  out
}

# The popup card and the crop viewer. `.psd-x` is the marker over a crop's
# centre: the crop is built around the detection, so the detection is dead
# centre and the overlay needs no projection to find it. The ring is left open
# in the middle, because a marker that covered a 30 m hull at this scale would
# hide exactly what the reader came to see.
#
# Panels are laid out in a row and sized against the viewport in both axes, so
# two crops side by side stay square and on screen without a media query.
psd_inspector_css <- function(mark = "#FF3B30", panels = 1) {

  size <- if (panels == 1) "min(74vh, 600px)" else sprintf("min(70vh, 520px, %dvw)",
                                                            floor(92 / panels))

  paste0(ps_map_title_css(), "
.psd-pop{font:12px/1.5 -apple-system,system-ui,Segoe UI,Roboto,sans-serif;color:#1a1a1a}
.psd-pop .psd-scene{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10px;
  color:#5a6672;word-break:break-all}
.psd-pop a.psd-thumb{display:inline-block;margin-top:.2rem;padding:.35rem .65rem;border-radius:4px;
  background:#12212b;color:#eaf4fa;text-decoration:none;font-weight:600;font-size:11.5px}
.psd-pop a.psd-thumb:hover{background:#1d3440}
.psd-pop .psd-dead{color:#8a949e;font-style:italic}
.psd-mmsi{font-variant-numeric:tabular-nums;letter-spacing:.02em}
.psd-lb{position:fixed;inset:0;z-index:9999;display:none;align-items:center;justify-content:center;
  background:rgba(6,10,16,.97)}
.psd-lb.on{display:flex}
.psd-lb-card{max-width:94vw;color:#e8edf2;
  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif}
.psd-lb-head{display:flex;align-items:center;gap:.45rem;padding-bottom:.5rem;font-size:.78rem;
  letter-spacing:.06em;text-transform:uppercase;color:#93a1ae}
.psd-lb-head .psd-lb-count{margin-right:auto}
.psd-lb-card button{background:none;border:1px solid #38434f;color:#c7d2dc;border-radius:4px;
  cursor:pointer;font-size:.95rem;line-height:1;padding:.2rem .55rem}
.psd-lb-card button:hover{border-color:#93a1ae;color:#fff}
.psd-frames{display:flex;gap:10px;align-items:flex-start}
.psd-label{font-size:.7rem;letter-spacing:.06em;text-transform:uppercase;color:#93a1ae;
  padding-bottom:.3rem;line-height:1}
.psd-frame{position:relative;line-height:0;background:#0a0f14;
  box-shadow:0 0 0 1px #33404d}
.psd-frame img{display:block;width:", size, ";height:", size, ";image-rendering:pixelated}
.psd-x{position:absolute;left:50%;top:50%;width:44px;height:44px;margin:-22px 0 0 -22px;
  pointer-events:none}
.psd-x i{position:absolute;inset:12px;border:1.5px solid ", mark, ";border-radius:50%}
.psd-x::before,.psd-x::after{content:'';position:absolute}
.psd-x::before{left:0;right:0;top:50%;height:1.5px;margin-top:-.75px;
  background:linear-gradient(to right,", mark, " 0 8px,transparent 8px calc(100% - 8px),
  ", mark, " calc(100% - 8px) 100%)}
.psd-x::after{top:0;bottom:0;left:50%;width:1.5px;margin-left:-.75px;
  background:linear-gradient(to bottom,", mark, " 0 8px,transparent 8px calc(100% - 8px),
  ", mark, " calc(100% - 8px) 100%)}
.psd-lb-meta{padding-top:.55rem;font-size:.8rem;line-height:1.55;max-width:94vw}
.psd-lb-meta .psd-scene{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10px;
  color:#8d99a5;word-break:break-all}
.psd-lb-foot{padding-top:.4rem;font-size:.72rem;color:#8d99a5}
.psd-dash{position:fixed;inset:0;display:flex;background:#0b1016;z-index:1}
.psd-dash-map{flex:1 1 auto;min-width:0;position:relative}
.psd-dash-side{flex:0 0 clamp(240px,32vw,460px);display:flex;flex-direction:column;
  border-left:1px solid #1e2833;background:#0b1016;
  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif}
.psd-side-head{padding:12px 14px 10px;color:#e8edf2;font-size:.85rem;
  border-bottom:1px solid #1e2833}
.psd-side-head b{font-size:1.05rem}
.psd-side-head span{display:block;font-size:.7rem;letter-spacing:.06em;text-transform:uppercase;
  color:#8d99a5;margin-top:3px}
.psd-grid{flex:1 1 auto;overflow-y:auto;padding:10px;display:grid;gap:7px;
  grid-template-columns:repeat(auto-fill,minmax(84px,1fr));align-content:start}
.psd-tile{position:relative;padding:0;background:#0a0f14;cursor:pointer;
  box-sizing:border-box;border:2px solid #1e2833}
.psd-tile img{display:block;width:100%;aspect-ratio:1/1;image-rendering:pixelated}
.psd-tile .psd-nope{display:block;width:100%;aspect-ratio:1/1;background:#11181f}
.psd-tile .psd-ring{position:absolute;left:50%;top:50%;width:15px;height:15px;margin:-7.5px 0 0 -7.5px;
  border:1px solid rgba(255,59,48,.85);border-radius:50%;pointer-events:none}
.psd-tile .psd-score{position:absolute;left:0;bottom:0;padding:1px 4px;font-size:9.5px;
  font-variant-numeric:tabular-nums;color:#dfe7ee;background:rgba(6,10,16,.72)}
.psd-tile.matched{outline:2px solid #4EC9E8}
.psd-tile:hover{outline:2px solid #93a1ae}
@keyframes psd-pulse{0%,100%{stroke-width:1;stroke-opacity:.9}
                    50%{stroke-width:8;stroke-opacity:1}}
.psd-pulse{animation:psd-pulse .55s ease-in-out infinite}
.psd-tile.on{outline:2px solid #FF3B30}
")
}

# `score`, `matched` and `tint` are each optional: a sensor with no score to show,
# no AIS match to mark, or no class to colour by passes NULL and the field is
# simply absent from the item, which the gallery reads as "nothing to draw".
psd_inspector_js <- function(src, caption, labels, lat, lon,
                            score = NULL, matched = NULL, tint = NULL) {

  # One entry per detection, each carrying one crop per view. `I()` keeps the
  # url list an array even when a single view makes it length one, so the panel
  # loop on the other side does not have to special-case it.
  #
  # The scalars ride along for the gallery, which reads this same array rather
  # than being handed its own copy — a second copy of the crops would double a
  # file that is already mostly pixels.
  items <- jsonlite::toJSON(
    lapply(seq_along(caption), function(i) {
      item <- list(urls = I(unname(vapply(src, `[`, character(1), i))),
                   meta = caption[i],
                   lat  = lat[i],
                   lon  = lon[i])
      # Assigned rather than declared, because `list(score = NULL)` keeps the
      # name and serialises to an empty object — which is not the same thing as
      # a field the gallery can skip.
      if (!is.null(score))   item$score   <- score[i]
      if (!is.null(matched)) item$matched <- isTRUE(matched[i])
      if (!is.null(tint))    item$tint    <- tint[i]
      item
    }),
    auto_unbox = TRUE, na = "null", digits = 8
  )

  sprintf("
function(el, x) {

  var items = %s, views = %s, at = 0;

  var box = document.createElement('div');
  box.className = 'psd-lb';
  box.innerHTML =
    '<div class=\"psd-lb-card\">' +
      '<div class=\"psd-lb-head\"><span class=\"psd-lb-count\"></span>' +
        '<button class=\"psd-nav\" data-d=\"-1\" title=\"Previous\">&lsaquo;</button>' +
        '<button class=\"psd-nav\" data-d=\"1\" title=\"Next\">&rsaquo;</button>' +
        '<button class=\"psd-close\" title=\"Close\">&times;</button></div>' +
      '<div class=\"psd-frames\">' + views.map(function(v) {
        // one line, deliberately: `return` on its own line would be a bare
        // `return;` after automatic semicolon insertion, and every panel
        // would come back undefined
        return '<div><div class=\"psd-label\">' + v + '</div>' +
               '<div class=\"psd-frame\"><img alt=\"Sentinel-2 crop\">' +
               '<div class=\"psd-x\"><i></i></div></div></div>';
      }).join('') +
      '</div>' +
      '<div class=\"psd-lb-meta\"></div>' +
    '</div>';
  document.body.appendChild(box);

  var imgs  = box.querySelectorAll('.psd-frame img'),
      meta  = box.querySelector('.psd-lb-meta'),
      count = box.querySelector('.psd-lb-count');

  function show(i) {
    if (!items.length) return;
    at = (i %% items.length + items.length) %% items.length;
    for (var k = 0; k < imgs.length; k++) {
      var u = items[at].urls[k];
      imgs[k].src = u || '';
      imgs[k].style.visibility = u ? 'visible' : 'hidden';
    }
    meta.innerHTML = items[at].meta;
    count.textContent = (at + 1) + ' / ' + items.length;
    box.classList.add('on');
  }

  function hide() {
    box.classList.remove('on');
    for (var k = 0; k < imgs.length; k++) imgs[k].src = '';
  }

  document.addEventListener('click', function(e) {
    var a = e.target.closest && e.target.closest('a.psd-thumb');
    if (!a || !el.contains(a)) return;
    e.preventDefault();
    show(parseInt(a.getAttribute('data-i'), 10));
  });

  box.addEventListener('click', function(e) {
    if (e.target === box || e.target.classList.contains('psd-close')) hide();
    var nav = e.target.closest && e.target.closest('.psd-nav');
    if (nav) show(at + parseInt(nav.getAttribute('data-d'), 10));
  });

  document.addEventListener('keydown', function(e) {
    if (!box.classList.contains('on')) return;
    if (e.key === 'Escape')     hide();
    if (e.key === 'ArrowRight') show(at + 1);
    if (e.key === 'ArrowLeft')  show(at - 1);
  });

  // Published for the gallery hook, which runs after this one on the same
  // element. Sharing the array is what keeps the crops from being sent twice.
  el.__psd = { items: items, show: show, hide: hide };
}", items, jsonlite::toJSON(labels))
}

# The second pane, added to the exported page only.
#
# It reads the viewer's own item array off the element rather than being handed
# its own — the thumbnails are the crops the page already carries, so a gallery
# of two hundred of them adds a few hundred bytes of markup and no pixels at all.
#
# The shell is fixed to the viewport because a standalone widget page has no
# layout to inherit: htmlwidgets leaves the map at an inline height and lets its
# fill CSS stretch it, which a flex parent would fight. Taking the viewport
# outright and moving the map into the left half is simpler than negotiating.
psd_gallery_js <- function(order_label = "by detection score") {
  sprintf("
function(el, x) {

  var api = el.__psd;
  if (!api || !api.items.length) return;
  var items = api.items, map = this;

  var shell = document.createElement('div');
  shell.className = 'psd-dash';
  shell.innerHTML = '<div class=\"psd-dash-map\"></div>' +
                    '<div class=\"psd-dash-side\">' +
                      '<div class=\"psd-side-head\"><b>' + items.length + '</b> detections' +
                      '<span>%s</span></div>' +
                      '<div class=\"psd-grid\"></div>' +
                    '</div>';
  document.body.appendChild(shell);

  shell.querySelector('.psd-dash-map').appendChild(el);
  el.classList.remove('html-fill-item');
  el.style.width = '100%%';
  el.style.height = '100%%';
  map.invalidateSize();

  var grid = shell.querySelector('.psd-grid');
  // The tint rides on the border, leaving `outline` to hover and selection — a
  // tile has to be able to say what it is and that it is the one being
  // looked at.
  grid.innerHTML = items.map(function(it, i) {
    var score = (typeof it.score === 'number') ? it.score.toFixed(2) : null;
    return '<button class=\"psd-tile' + (it.matched ? ' matched' : '') + '\" data-i=\"' + i + '\"' +
           (it.tint ? ' style=\"border-color:' + it.tint + '\"' : '') +
           (score ? ' title=\"score ' + score + '\"' : '') + '>' +
           (it.urls[0] ? '<img src=\"' + it.urls[0] + '\" alt=\"\">' : '<span class=\"psd-nope\"></span>') +
           '<span class=\"psd-ring\"></span>' +
           (score ? '<span class=\"psd-score\">' + score + '</span>' : '') + '</button>';
  }).join('');

  var tiles = grid.querySelectorAll('.psd-tile'), current = -1;

  function select(i, scroll) {
    if (current > -1 && tiles[current]) tiles[current].classList.remove('on');
    current = i;
    if (i < 0 || !tiles[i]) return;
    tiles[i].classList.add('on');
    if (scroll) tiles[i].scrollIntoView({ block: 'center' });
  }

  // Markers are found by position rather than by insertion order, which leaflet
  // does not promise to preserve when iterating its layers. The search happens
  // on demand and not once up front: this hook runs before leaflet has put its
  // vector layers on the map, so a table built here would be empty for good.
  var key = function(a, b) { return a.toFixed(5) + ',' + b.toFixed(5); };
  var indexAt = {};
  items.forEach(function(it, i) { indexAt[key(it.lat, it.lon)] = i; });

  function markerFor(it) {
    var want = key(it.lat, it.lon), found = null;
    map.eachLayer(function(l) {
      if (found || !l.getLatLng || !l.setStyle) return;
      var p = l.getLatLng();
      if (key(p.lat, p.lng) === want) found = l;
    });
    return found;
  }

  // Hovering a tile pulses its marker, so the eye can cross from the contact
  // sheet to the place without spending a click to find out where it is.
  // `mouseover` rather than `mouseenter` because only the former bubbles, and
  // one listener on the grid beats one per tile.
  var pulsing = null;
  function pulse(it) {
    if (pulsing) { pulsing.classList.remove('psd-pulse'); pulsing = null; }
    if (!it) return;
    var mk = markerFor(it);
    var el = mk && (mk.getElement ? mk.getElement() : mk._path);
    if (!el) return;
    mk.bringToFront();          // before the class: re-inserting restarts it
    el.classList.add('psd-pulse');
    pulsing = el;
  }

  grid.addEventListener('mouseover', function(e) {
    var t = e.target.closest && e.target.closest('.psd-tile');
    pulse(t ? items[parseInt(t.getAttribute('data-i'), 10)] : null);
  });
  grid.addEventListener('mouseleave', function() { pulse(null); });

  grid.addEventListener('click', function(e) {
    var t = e.target.closest && e.target.closest('.psd-tile');
    if (!t) return;
    var i = parseInt(t.getAttribute('data-i'), 10), it = items[i];
    select(i, false);
    map.setView([it.lat, it.lon], Math.max(map.getZoom(), 11));
    var mk = markerFor(it);
    if (mk) mk.openPopup();
    api.show(i);
  });

  // The other direction: whichever detection the map is showing, the gallery
  // scrolls to it, so the two panes are never describing different things.
  map.on('popupopen', function(e) {
    var p = e.popup.getLatLng();
    if (!p) return;
    var i = indexAt[key(p.lat, p.lng)];
    if (i != null) select(i, true);
  });
}", order_label)
}

# saveWidget(selfcontained = TRUE) shells out to pandoc. Quarto ships a copy but
# does not put it on R's path, so a knitr chunk that would otherwise be fine
# fails at export time. Point rmarkdown at Quarto's copy when nothing else is
# findable.
ensure_pandoc <- function() {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) return(invisible(FALSE))
  if (rmarkdown::pandoc_available()) return(invisible(TRUE))
  dirs  <- file.path(Sys.getenv("QUARTO_BIN_PATH"), "tools", c(R.version$arch, ""))
  found <- dirs[file.exists(file.path(dirs, "pandoc"))]
  if (length(found) > 0) rmarkdown::find_pandoc(dir = found[[1]])
  invisible(rmarkdown::pandoc_available())
}
