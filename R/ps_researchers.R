#' Scientists Lookup Table
#'
#' Directory of Pristine Seas scientists and collaborators with contact information,
#' affiliations, and research specialties.
#'
#' @format A data frame with scientist information
#' @details
#' **status** categories:
#' - **core** — Full-time Pristine Seas staff
#' - **affiliate** — Regular collaborators and partners
#' - **visiting** — Visiting scientists and temporary collaborators
#' - **Emeritus** - Retired team member
#' - **Local** - Local participant
#' @export
#'
ps_researchers <- tibble::tribble(~initials, ~name,               ~affiliation,           ~status,        ~specialties,
                                  "JSM",     "Juan Mayorga",      "Pristine Seas",        "Core",         "Data science, Spatial analysis, Marine conservation",
                                  "AKM",     "Andrew McInnis",    "Pristine Seas",        "Core",         "Coral ecology ",
                                  "LY",      "Lindsay Young",     "Pristine Seas",        "Core",         "Seabirds",
                                  "MT",      "Molly Timmers",     "Pristine Seas",        "Core",         "eDNA, invetebrates, coral reef ecology",
                                  "CT",      "Chris Thompson",    "Pristine Seas",        "Core",         "Seabirds and pelagic ecology",
                                  "KM",      "Kat Millage",       "Pristine Seas",        "Core",         "Data science, Spatial analysis, Marine conservation",
                                  "WG",      "Whitney Goodell",   "Pristine Seas",        "Core",         "Deep sea ecology",
                                  "JEC",     "Jennifer Caselle",  "UCSB",                 "Affiliate",    "Kelp forest ecology, Temperate reef systems, California",
                                  "EC",      "Emma Cebrian",      "CSIC",                 "Affiliate",    "Benthic ecology",
                                  "QG",      "Quim Garrabou",     "CSIC",                 "Affiliate",    "Benthic ecology",
                                  "EB",      "Eric Brown",        "NPS",                  "Visiting",     "Coral ecology",
                                  "AD",      "Alyssa Adler",      "Duke University",      "Visiting",     "ROV",
                                  "VAS",     "Vyvyan Summers",    "Independent",          "Visiting",     "BRUVS",
                                  "ALG",     "Alison Green",      "Independent",          "Visiting",     "Fish ecology",
                                  "SAS",     "Stuart Sandin",     "Scripps",              "Visiting",     "Fish ecology",
                                  "AMF",     "Alan Friedlander",  "University of Hawaii", "Emeritus",     "Fish ecology",
                                  "KB",      "Kike Ballesteros",  "CEAB",                 "Emeritus",     "Benthic ecology",
                                  "YW",      "Yvonne Wong",       "Pristine Seas",        "Local",        "Stakeholder engagement")
