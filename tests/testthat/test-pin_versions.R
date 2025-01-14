test_that("can use old pin_versions() api", {
  board <- board_register_local()
  board %>% pin_write(x = 1:5, "x")

  expect_snapshot({
    x <- pin_versions("x")
    x <- pin_versions("x", "local")
    x <- pin_versions("x", board)
  })
})

test_that("`full` is deprecated", {
  board <- board_temp()
  board %>% pin_write(x = 1:5, "x")

  expect_snapshot({
    x <- pin_versions(board, "x", full = TRUE)
  })
})
