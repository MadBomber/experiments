#!/usr/bin/env ruby
# random_bible_book/content_builder.rb
#
# This is the content for each bible book.  The
# program codes this content into HTML for insert
# into some web page.

require 'debug_me'
include DebugMe

require 'pathname'

KEY_VERSES = (Pathname.pwd + 'key_verse.txt').read.split("\n")

CONTENT = DATA.read.split("\n")


Book = Struct.new(:name, :desc, :verse)

books = []

66.times do |inx|
  x = inx * 3
  break if x >= CONTENT.size

  books << Book.new

  books.last.name   = CONTENT[x + 0]
  books.last.desc   = CONTENT[x + 1]
  books.last.verse  = KEY_VERSES[inx]
end


debug_me{[
  :books,
  'books.size'
]}

__END__
Genesis
Genesis speaks of beginnings and is foundational to the understanding of the rest of the Bible. It is supremely a book that speaks about relationships, highlighting those between God and his creation, between God and humankind, and between human beings.

Exodus
Exodus describes the history of the Israelites leaving Egypt after slavery. The book lays a foundational theology in which God reveals his name, his attributes, his redemption, his law and how he is to be worshiped.

Leviticus
Leviticus receives its name from the Septuagint (the pre-Christian Greek translation of the Old Testament) and means &quot;concerning the Levites&quot; (the priests of Israel). It serves as a manual of regulations enabling the holy King to set up his earthly throne among the people of his kingdom. It explains how they are to be his holy people and to worship him in a holy manner.

Numbers
Numbers relates the story of Israel&#39;s journey from Mount Sinai to the plains of Moab on the border of Canaan. The book tells of the murmuring and rebellion of God&#39;s people and of their subsequent judgment.

Deuteronomy
Deuteronomy (&quot;repetition of the Law&quot;) serves as a reminder to God&#39;s people about His covenant. The book is a &quot;pause&quot; before Joshua&#39;s conquest begins and a reminder of what God required.

Joshua
Joshua is a story of conquest and fulfillment for the people of God. After many years of slavery in Egypt and 40 years in the desert, the Israelites were finally allowed to enter the land promised to their fathers.

Judges
The book of Judges depicts the life of Israel in the Promised Land—from the death of Joshua to the rise of the monarchy. It tells of urgent appeals to God in times of crisis and apostasy, moving the Lord to raise up leaders (judges) through whom He throws off foreign oppressors and restores the land to peace.

Ruth
The book of Ruth has been called one of the best examples of short narrative ever written. It presents an account of the remnant of true faith and piety in the period of the judges through the fall and restoration of Naomi and her daughter-in-law Ruth (an ancestor of King David and Jesus).

1 Samuel
Samuel relates God&#39;s establishment of a political system in Israel headed by a human king. Through Samuel&#39;s life, we see the rise of the monarchy and the tragedy of its first king, Saul.

2 Samuel
After the failure of King Saul, 2 Samuel depicts David as a true (though imperfect) representative of the ideal theocratic king. Under David&#39;s rule the Lord caused the nation to prosper, to defeat its enemies, and to realize the fulfillment of His promises.

1 Kings
1 Kings continues the account of the monarchy in Israel and God&#39;s involvement through the prophets. After David, his son Solomon ascends the throne of a united kingdom, but this unity only lasts during his reign. The book explores how each subsequent king in Israel and Judah answers God&#39;s call—or, as often happens, fails to listen.

2 Kings
2 Kings carries the historical account of Judah and Israel forward. The kings of each nation are judged in light of their obedience to the covenant with God. Ultimately, the people of both nations are exiled for disobedience.

1 Chronicles
Just as the author of Kings had organized and interpreted Israel&#39;s history to address the needs of the exiled community, so the writer of 1 Chronicles wrote for the restored community another history.

2 Chronicles
2 Chronicles continues the account of Israel&#39;s history with an eye for restoration of those who had returned from exile.

Ezra
The book of Ezra relates how God&#39;s covenant people were restored from Babylonian exile to the covenant land as a theocratic (kingdom of God) community even while continuing under foreign rule.

Nehemiah
Closely related to the book of Ezra, Nehemiah chronicles the return of this &quot;cupbearer to the king&quot; and the challenges he and the other Israelites face in their restored homeland.

Esther
Esther records the institution of the annual festival of Purim through the historical account of Esther, a Jewish girl who becomes queen of Persia and saves her people from destruction.

Job
Through a series of monologues, the book of Job relates the account of a righteous man who suffers under terrible circumstances. The book&#39;s profound insights, its literary structures, and the quality of its rhetoric display the author&#39;s genius.

Psalms
The Psalms are collected songs and poems that represent centuries worth of praises and prayers to God on a number of themes and circumstances. The Psalms are impassioned, vivid and concrete; they are rich in images, in simile and metaphor.

Proverbs
Proverbs was written to give &quot;prudence to the simple, knowledge and discretion to the young,&quot; and to make the wise even wiser. The frequent references to &quot;my son(s)&quot; emphasize instructing the young and guiding them in a way of life that yields rewarding results.

Ecclesiastes
The author of Ecclesiastes puts his powers of wisdom to work to examine the human experience and assess the human situation. His perspective is limited to what happens &quot;under the sun&quot; (as is that of all human teachers).

Song of Songs
In ancient Israel everything human came to expression in words: reverence, gratitude, anger, sorrow, suffering, trust, friendship, commitment. In the Song of Solomon, it is love that finds words–inspired words that disclose its exquisite charm and beauty as one of God&#39;s choicest gifts.

Isaiah
Isaiah son of Amoz is often thought of as the greatest of the writing prophets. His name means &quot;The Lord saves.&quot; Isaiah is a book that unveils the full dimensions of God&#39;s judgment and salvation.

Jeremiah
This book preserves an account of the prophetic ministry of Jeremiah, whose personal life and struggles are shown to us in greater depth and detail than those of any other Old Testament prophet.

Lamentations
Lamentations consists of a series of poetic and powerful laments over the destruction of Jerusalem (the royal city of the Lord&#39;s kingdom) in 586 B.C.

Ezekiel
The Old Testament in general and the prophets in particular presuppose and teach God&#39;s sovereignty over all creation and the course of history. And nowhere in the Bible are God&#39;s initiative and control expressed more clearly and pervasively than in the book of the prophet Ezekiel.

Daniel
Daniel captures the major events in the life of the prophet Daniel during Israel&#39;s exile. His life and visions point to God&#39;s plans of redemption and sovereign control of history.

Hosea
The prophet Hosea son of Beeri lived in the tragic final days of the northern kingdom. His life served as a parable of God&#39;s faithfulness to an unfaithful Israel.

Joel
The prophet Joel warned the people of Judah about God&#39;s coming judgment—and the coming restoration and blessing that will come through repentance.

Amos
Amos prophesied during the reigns of Uzziah over Judah (792-740 B.C.) and Jeroboam II over Israel (793-753).

Obadiah
The prophet Obadiah warned the proud people of Edom about the impending judgment coming upon them.

Jonah
Jonah is unusual as a prophetic book in that it is a narrative account of Jonah&#39;s mission to the city of Nineveh, his resistance, his imprisonment in a great fish, his visit to the city, and the subsequent outcome.

Micah
Micah prophesied sometime between 750 and 686 B.C. during the reigns of Jotham, Ahaz, and Hezekiah, kings of Judah. Israel was in an apostate condition. Micah predicted the fall of her capital, Samaria, and also foretold the inevitable desolation of Judah.

Nahum
The book contains the &quot;vision of Nahum,&quot; whose name means &quot;comfort.&quot; The focal point of the entire book is the Lord&#39;s judgment on Nineveh for her oppression, cruelty, idolatry, and wickedness.

Habakkuk
Little is known about Habakkuk except that he was a contemporary of Jeremiah and a man of vigorous faith. The book bearing his name contains a dialogue between the prophet and God concerning injustice and suffering.

Zephaniah
The prophet Zephaniah was evidently a person of considerable social standing in Judah and was probably related to the royal line. The intent of the author was to announce to Judah God&#39;s approaching judgment.

Haggai
Haggai was a prophet who, along with Zechariah, encouraged the returned exiles to rebuild the temple. His prophecies clearly show the consequences of disobedience. When the people give priority to God and his house, they are blessed.

Zechariah
Like Jeremiah and Ezekiel, Zechariah was not only a prophet, but also a member of a priestly family. The chief purpose of Zechariah (and Haggai) was to rebuke the people of Judah and to encourage and motivate them to complete the rebuilding of the temple.

Malachi
Malachi, whose name means &quot;my messenger,&quot; spoke to the Israelites after their return from exile. The theological message of the book can be summed up in one sentence: The Great King will come not only to judge his people, but also to bless and restore them.

Matthew
Matthew&#39;s main purpose in writing his Gospel (the &quot;good news&quot;) is to prove to his Jewish readers that Jesus is their Messiah. He does this primarily by showing how Jesus in his life and ministry fulfilled the Old Testament Scriptures.

Mark
Since Mark&#39;s Gospel (the &quot;good news&quot;) is traditionally associated with Rome, it may have been occasioned by the persecutions of the Roman church in the period c. A.D. 64-67. Mark may be writing to prepare his readers for such suffering by placing before them the life of our Lord.

Luke
Luke&#39;s Gospel (the &quot;good news&quot;) was written to strengthen the faith of all believers and to answer the attacks of unbelievers. It was presented to debunk some disconnected and ill-founded reports about Jesus. Luke wanted to show that the place of the Gentile (non-Jewish) Christian in God&#39;s kingdom is based on the teaching of Jesus.

John
John&#39;s Gospel (the &quot;good news&quot;) is rather different from the other three, highlighting events not detailed in the others. The author himself states his main purpose clearly in 20:31: &quot;that you may believe that Jesus is the Christ, the Son of God, and that by believing you may have life in his name.&quot;

Acts
The book of Acts provides a bridge for the writings of the New Testament. As a second volume to Luke&#39;s Gospel, it joins what Jesus &quot;began to do and to teach&quot; as told in the Gospels with what he continued to do and teach through the apostles&#39; preaching and the establishment of the church.

Romans
Paul&#39;s primary theme in Romans is presenting the gospel (the &quot;good news&quot;), God&#39;s plan of salvation and righteousness for all humankind, Jew and non-Jew alike.

1 Corinthians
The first letter to the Corinthians revolves around the theme of problems in Christian conduct in the church. It thus has to do with progressive sanctification, the continuing development of a holy character. Obviously Paul was personally concerned with the Corinthians&#39; problems, revealing a true pastor&#39;s (shepherd&#39;s) heart.

2 Corinthians
Because of the occasion that prompted this letter, Paul had a number of purposes in mind: to express the comfort and joy Paul felt because the Corinthians had responded favorably to his painful letter; to let them know about the trouble he went through in the province of Asia; and to explain to them the true nature (its joys, sufferings and rewards) and high calling of Christian ministry.

Galatians
Galatians stands as an eloquent and vigorous apologetic for the essential New Testament truth that people are justified by faith in Jesus Christ—by nothing less and nothing more—and that they are sanctified not by legalistic works but by the obedience that comes from faith in God&#39;s work for them.

Ephesians
Unlike several of the other letters Paul wrote, Ephesians does not address any particular error or heresy. Paul wrote to expand the horizons of his readers, so that they might understand better the dimensions of God&#39;s eternal purpose and grace and come to appreciate the high goals God has for the church.

Philippians
Paul&#39;s primary purpose in writing this letter was to thank the Philippians for the gift they had sent him upon learning of his detention at Rome. However, he makes use of this occasion to fulfill several other desires: (1) to report on his own circumstances; (2) to encourage the Philippians to stand firm in the face of persecution and rejoice regardless of circumstances; and (3) to exhort them to humility and unity.

Colossians
Paul&#39;s purpose is to refute the Colossian heresy. To accomplish this goal, he exalts Christ as the very image of God, the Creator, the preexistent sustainer of all things, the head of the church, the first to be resurrected, the fullness of deity (God) in bodily form, and the reconciler.

1 Thessalonians
Although the thrust of the letter is varied, the subject of eschatology (doctrine of last things) seems to be predominant in both Thessalonian letters. Every chapter of 1 Thessalonians ends with a reference to the second coming of Christ.

2 Thessalonians
Since the situation in the Thessalonian church has not changed substantially, Paul&#39;s purpose in writing is very much the same as in his first letter to them. He writes (1) to encourage persecuted believers, (2) to correct a misunderstanding concerning the Lord&#39;s return, and (3) to exhort the Thessalonians to be steadfast and to work for a living.

1 Timothy
During his fourth missionary journey, Paul had instructed Timothy to care for the church at Ephesus while he went on to Macedonia. When he realized that he might not return to Ephesus in the near future, he wrote this first letter to Timothy to develop the charge he had given his young assistant. This is the first of the &quot;Pastoral Epistles.&quot;

2 Timothy
Paul was concerned about the welfare of the churches during this time of persecution under Nero, and he admonishes Timothy to guard the gospel, to persevere in it, to keep on preaching it, and, if necessary, to suffer for it. This is the second &quot;Pastoral Epistle.&quot;

Titus
Apparently Paul introduced Christianity in Crete when he and Titus visited the island, after which he left Titus there to organize the converts. Paul sent the letter with Zenas and Apollos, who were on a journey that took them through Crete, to give Titus personal authorization and guidance in meeting opposition, instructions about faith and conduct, and warnings about false teachers. This is the last of the &quot;Pastoral Epistles.&quot;

Philemon
To win Philemon&#39;s willing acceptance of the runaway slave Onesimus, Paul writes very tactfully and in a lighthearted tone, which he creates with wordplay. The appeal is organized in a way prescribed by ancient Greek and Roman teachers: to build rapport, to persuade the mind, and to move the emotions.

Hebrews
The theme of Hebrews is the absolute supremacy and sufficiency of Jesus Christ as revealer and as mediator of God&#39;s grace. A striking feature of this presentation of the gospel is the unique manner in which the author employs expositions of eight specific passages of the Old Testament Scriptures.

James
Characteristics that make the letter distinctive are: (1) its unmistakably Jewish nature; (2) its emphasis on vital Christianity, characterized by good deeds and a faith that works (genuine faith must and will be accompanied by a consistent lifestyle); (3) its simple organization; (4) and its familiarity with Jesus&#39; teachings preserved in the Sermon on the Mount.

1 Peter
Although 1 Peter is a short letter, it touches on various doctrines and has much to say about Christian life and duties. It is not surprising that different readers have found it to have different principal themes. For example, it has been characterized as a letter of separation, of suffering and persecution, of suffering and glory, of hope, of pilgrimage, of courage, and as a letter dealing with the true grace of God.

2 Peter
In his first letter Peter feeds Christ&#39;s sheep by instructing them how to deal with persecution from outside the church; in this second letter he teaches them how to deal with false teachers and evildoers who have come into the church.

1 John
John&#39;s readers were confronted with an early form of Gnostic teaching of the Cerinthian variety. This heresy was also libertine, throwing off all moral restraints. Consequently, John wrote this letter with two basic purposes in mind: (1) to expose false teachers and (2) to give believers assurance of salvation.

2 John
During the first two centuries the gospel was taken from place to place by traveling evangelists and teachers. Believers customarily took these missionaries into their homes and gave them provisions for their journey when they left. Since Gnostic teachers also relied on this practice, 2 John was written to urge discernment in supporting traveling teachers

3 John
Itinerant teachers sent out by John were rejected in one of the churches in the province of Asia by a dictatorial leader, Diotrephes, who even excommunicated members who showed hospitality to John&#39;s messengers. John wrote this letter to commend Gaius for supporting the teachers and, indirectly, to warn Diotrephes.

Jude
Although Jude was very eager to write to his readers about salvation, he felt that he must instead warn them about certain immoral men circulating among them who were perverting the grace of God. Apparently these false teachers were trying to convince believers that being saved by grace gave them license to sin since their sins would no longer be held against them.

Revelation
John writes to encourage the faithful to resist staunchly the demands of emperor worship. He informs his readers that the final showdown between God and Satan is imminent. Satan will increase his persecution of believers, but they must stand fast, even to death. They are sealed against any spiritual harm and will soon be vindicated when Christ returns, when the wicked are forever destroyed, and when God&#39;s people enter an eternity of glory and blessedness.
