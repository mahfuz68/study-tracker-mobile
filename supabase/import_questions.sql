-- Full question bank import (244 questions from Neon)
-- Run this after import_from_neon.sql

INSERT INTO questions (id, subject, topic, question, option_a, option_b, option_c, option_d, correct, explanation, created_at)
VALUES
  (5,'বাংলা সাহিত্য','প্রাচীন যুগ','চর্যাপদের খণ্ডিত পদগুলো তিব্বতি থেকে প্রাচীন বাংলায় রূপান্তর করেন- ৪৯তম বিসিএস)','সুনীতিকুমার চট্টোপাধ্যায়','হরপ্রসাদ শাস্ত্রী','রাজেন্দ্রলাল মিত্র','সুকুমার সেন',3,'According to the provided answer key in the document, Sukumar Sen is indicated as the correct answer.','2026-06-08 13:22:08.975'::timestamptz),
  (6,'বাংলা সাহিত্য','প্রাচীন যুগ','চর্যাপদের বর্ণনা অনুযায়ী ডোম্বীদের পেশা কি ছিল? [৪৯তম বিসিএস (বাংলা))','মদ চোয়ানো','চাঙারি তৈরি','তাঁত বোনা','উপরের তিনটিই',3,'The Charyapada describes the Dom community as engaged in various professions including brewing alcohol, making baskets, and weaving.','2026-06-08 13:22:08.975'::timestamptz),
  (7,'বাংলা সাহিত্য','প্রাচীন যুগ','''চর্যাচর্যবিনিশ্চয়'' এর অর্থ কি? [৪৯তম বিসিএস (বাংলা) / ৩৭তম বিসিএস)','কোনটি চর্যাগান, আর কোনটি নয়','কোনটি আচরণীয়, আর কোনটি নয়','কোনটি চরাচরের, আর কোনটি নয়','কোনটি আচার্যের, আর কোনটি নয়',1,'চর্যাচর্যবিনিশ্চয় literally translates to what is to be practiced and what is not to be practiced.','2026-06-08 13:22:08.975'::timestamptz),
  (8,'বাংলা সাহিত্য','প্রাচীন যুগ','চর্যাপদের ভাষাকে ''আলো আঁধারি'' বলে অভিহিত করেন কে? (৪৯তম বিসিএস (বাংলা)]','ডঃ মুহাম্মদ শহীদুল্লাহ','সুনীতিকুমার চট্টোপাধ্যায়','হরপ্রসাদ শাস্ত্রী','সুকুমার সেন',2,'Haraprasad Shastri termed its language Sandhya Bhasha or আলো আঁধারি.','2026-06-08 13:22:08.975'::timestamptz),
  (9,'বাংলা সাহিত্য','প্রাচীন যুগ','চর্যাপদের কোন কবি নিজেকে বাঙালি বলে পরিচয় দিয়েছেন? [৪৯তম বিসিএস (বাংলা) / ৩০তম বিসিএস)','লুইপা','কাহ্নপা','কুকুরী পা','ভুসুকুপা',3,'Bhusukupa identified himself as a Bengali in his Charyapada verse.','2026-06-08 13:22:08.975'::timestamptz),
  (10,'বাংলা সাহিত্য','প্রাচীন যুগ','''লুই ভণই গুরু পুছিঅ জান।''- এখানে ''ভণই'' শব্দের অর্থ কী? [৪৭তম বিসিএস]','বলে','ভাবে','গায়','দেখে',0,'ভণই (bhanai) is a verb form meaning says or tells.','2026-06-08 13:22:08.975'::timestamptz)
ON CONFLICT DO NOTHING;
