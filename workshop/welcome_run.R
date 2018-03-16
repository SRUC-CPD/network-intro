library("rmarkdown")

users = read.csv("~/Temporary_Users.csv")

for(i in 1:nrow(users)){
   render("~/repo/network-intro/workshop/welcome.Rmd",
          output_file=paste0("~/repo/network-intro/workshop/logins/welcome_", users[i, 1], ".pdf"))
}
