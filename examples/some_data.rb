# frozen_string_literal: true

user1 = User.create!(username: "maxlap")

my_post = user1.posts.create!(title: "First post", content: "This is new")
my_post.comments.create!(author: user1, content: "Commenting on my own post!")
