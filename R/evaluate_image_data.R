# read in site data

images_sr <- readr::read_csv("/backup/see_it_grow/SR2020/Reports/SR2020_RepeatPicturesDetails_3-5-2021.csv")
images_lr <- readr::read_csv("/backup/see_it_grow/LR2020/Reports/LR2020_Repeat_Picture_Details_2021-05-03T05_01_10.410Z.csv")

images <- bind_rows(images_sr, images_lr)
