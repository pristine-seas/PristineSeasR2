# A fake Drive, laid out the ways Drive for Desktop lays it out
fake_drive <- function(root, account = "GoogleDrive-someone@ngs.org", where = "My Drive") {
  acct <- file.path(root, "Library", "CloudStorage", account)
  base <- switch(where,
    "My Drive"  = file.path(acct, "My Drive", "Pristine Seas", "SCIENCE"),
    "shortcut"  = file.path(acct, ".shortcut-targets-by-id", "16vjFvz", "Pristine Seas", "SCIENCE"),
    "shared"    = file.path(acct, "Shared drives", "Science", "Pristine Seas", "SCIENCE"))
  dir.create(file.path(base, "expeditions"), recursive = TRUE, showWarnings = FALSE)
  normalizePath(base, winslash = "/")
}

test_that("the override wins, and a wrong override is an error", {
  home <- withr::local_tempdir()
  sci  <- fake_drive(home)
  withr::local_envvar(PS_SCIENCE_PATH = sci)
  expect_identical(ps_science_paths()$science, sci)
  expect_identical(basename(ps_science_paths()$datasets), "datasets")

  withr::local_envvar(PS_SCIENCE_PATH = file.path(home, "nowhere"))
  expect_error(ps_science_paths(), "does not exist")
})

test_that("SCIENCE is found in My Drive, in a shortcut, and in a Shared drive", {
  for (where in c("My Drive", "shortcut", "shared")) {
    home <- withr::local_tempdir()
    sci  <- fake_drive(home, where = where)
    roots <- PristineSeasR2:::.ps_drive_roots(os = "Darwin", home = home)
    hits  <- PristineSeasR2:::.ps_science_candidates(roots)
    expect_identical(normalizePath(hits[1], winslash = "/"), sci, info = where)
  }
})

test_that("an ngs.org account beats a personal one, and empty folders do not count", {
  home <- withr::local_tempdir()
  personal <- fake_drive(home, account = "GoogleDrive-someone@gmail.com")
  ngs      <- fake_drive(home, account = "GoogleDrive-someone@ngs.org")
  empty    <- file.path(home, "Library", "CloudStorage", "GoogleDrive-other@ngs.org",
                        "My Drive", "Pristine Seas", "SCIENCE")
  dir.create(empty, recursive = TRUE)

  roots <- PristineSeasR2:::.ps_drive_roots(os = "Darwin", home = home)
  hits  <- PristineSeasR2:::.ps_science_candidates(roots)

  expect_identical(normalizePath(hits[1], winslash = "/"), ngs)
  expect_true(personal %in% normalizePath(hits, winslash = "/"))
  expect_false(normalizePath(empty, winslash = "/") %in% normalizePath(hits, winslash = "/"))
})

test_that("a re-login copy of an account ranks below the live one", {
  home  <- withr::local_tempdir()
  stale <- fake_drive(home, account = "GoogleDrive-someone@ngs.org (3-9-26 12:34)")
  live  <- fake_drive(home, account = "GoogleDrive-someone@ngs.org")
  hits  <- PristineSeasR2:::.ps_science_candidates(PristineSeasR2:::.ps_drive_roots(os = "Darwin", home = home))
  expect_identical(normalizePath(hits[1], winslash = "/"), live)
})

test_that("nothing found is a clear error that lists what was searched", {
  home <- withr::local_tempdir()
  dir.create(file.path(home, "Library", "CloudStorage", "GoogleDrive-x@ngs.org", "My Drive"), recursive = TRUE)
  withr::local_envvar(PS_SCIENCE_PATH = "")
  withr::local_options(PristineSeasR2.science_path = NULL)
  local_mocked_bindings(.ps_drive_roots = function(...) file.path(home, "Library", "CloudStorage", "GoogleDrive-x@ngs.org"))
  expect_error(ps_science_paths(), "Could not find .Pristine Seas/SCIENCE.")
})

test_that("get_drive_paths() is a plain alias", {
  home <- withr::local_tempdir()
  sci  <- fake_drive(home)
  withr::local_envvar(PS_SCIENCE_PATH = sci)
  expect_identical(get_drive_paths(), ps_science_paths())
})
