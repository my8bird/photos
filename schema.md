Ideas
=====
comments could have happiness rating which affects the user and photo
face detection/recog

rolling average
---------------
store total
store samplesize
on new sample grab add the sample inc the size and divide.  then multiply both by some constant < 1.  this last step will new data to be treated as "better"


Needed
======
users
photos
comments
ratings

users in photo
user comments
photo comments

user1 mentioned by user2
user1 mentioned user2


Ideas
=====
Mongo
-----
photo
 _id
 added: {date: <date>, user: <user>}
 users_in: [{user_id: ##, location: [0,0]}]

 title:
 description:

 updated: <date>
 
 rating: {total: ##, count: ##}
 path: s3://kasjdflkajsdflkasjflkasjdflaskjdf.png

 tags: [str]

 comments: [{
   user: <must be index.
   date:
   text:
 }]


user:
 id:
 name:
 
