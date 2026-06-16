-- =============================================================
-- Import data from Neon (Next.js webapp) into Supabase
-- =============================================================
-- Prerequisites:
--   1. Run supabase/migration.sql first to create the schema
--   2. Run this in Supabase SQL Editor (uses service_role)
-- =============================================================

-- ── Helper: deterministic UUID v5 from old text IDs ────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION neon_uuid(old_id text)
RETURNS uuid AS $$
  SELECT uuid_generate_v5(
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid,  -- DNS namespace
    old_id
  );
$$ LANGUAGE sql IMMUTABLE;

-- ═════════════════════════════════════════════════════════════════
-- STEP 1: Create users in auth.users (Supabase-managed)
-- ═════════════════════════════════════════════════════════════════
-- Note: If this INSERT fails, use Supabase Auth Dashboard to
-- create users manually with the same emails, then re-run
-- starting from STEP 2 with old→new ID mapping filled in.

DO $$
DECLARE
  uid uuid;
BEGIN
  -- User 1: mymsicret18@gmail.com / password from bcrypt hash
  uid := neon_uuid('cmq1t9o6q0000hz01nrr0arnc');
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
  VALUES (uid, 'mymsicret18@gmail.com',
    '$2a$12$JJ22ojgjkdglfKtJCmcFx.xmBnySNmTJ.HmTYoUhRpGgCrupNMMz2',
    now(), '{"provider":"email"}', '{"name":"Mahfuz Anam","role":"USER"}',
    now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO profiles (id, name, email, role, share_token, created_at)
  VALUES (uid, 'Mahfuz Anam', 'mymsicret18@gmail.com', 'USER',
    'd908b39fbb70c0b6dd07b0364a1b41281717ce977e646b96', now())
  ON CONFLICT DO NOTHING;

  -- User 2: mymsicret19@gmail.com (ADMIN)
  uid := neon_uuid('cmq36w8rm0000c4efwka6y3qi');
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
  VALUES (uid, 'mymsicret19@gmail.com',
    '$2a$12$JJ22ojgjkdglfKtJCmcFx.xmBnySNmTJ.HmTYoUhRpGgCrupNMMz2',
    now(), '{"provider":"email"}', '{"name":"Mahfuz Anam","role":"ADMIN"}',
    now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO profiles (id, name, email, role, share_token, created_at)
  VALUES (uid, 'Mahfuz Anam', 'mymsicret19@gmail.com', 'ADMIN',
    '15ea79091497407578a996a1956f3d46420526f055b509a9', now())
  ON CONFLICT DO NOTHING;

  -- User 3: mymsicret20@gmail.com
  uid := neon_uuid('cmq3o5qeh0000pzr29szukzqh');
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
  VALUES (uid, 'mymsicret20@gmail.com',
    '$2a$12$JJ22ojgjkdglfKtJCmcFx.xmBnySNmTJ.HmTYoUhRpGgCrupNMMz2',
    now(), '{"provider":"email"}', '{"name":"Mahfuz Anam","role":"USER"}',
    now(), now(), 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO profiles (id, name, email, role, share_token, created_at)
  VALUES (uid, 'Mahfuz Anam', 'mymsicret20@gmail.com', 'USER', NULL, now())
  ON CONFLICT DO NOTHING;

  -- User 4: mymsicret21@gmail.com
  uid := neon_uuid('cmq50t67r00009m9pz33dfmgw');
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
  VALUES (uid, 'mymsicret21@gmail.com',
    '$2a$12$WMWZKi/xTd4MNLnXkz8jP.jn4dXkVnRGgEFczmNhjBqtBlV21iSau',
    now(), '{"provider":"email"}', '{"name":"Mahfuz Anam","role":"USER"}',
    now(), now(), 'authenticated', 'authenticated')
   ON CONFLICT (id) DO NOTHING;

  INSERT INTO profiles (id, name, email, role, share_token, created_at)
  VALUES (uid, 'Mahfuz Anam', 'mymsicret21@gmail.com', 'USER', NULL, now())
  ON CONFLICT DO NOTHING;

  RAISE NOTICE '✅ Users and profiles created';
END $$;

-- ═════════════════════════════════════════════════════════════════
-- STEP 2: Static data (study_days, topics)
-- ═════════════════════════════════════════════════════════════════

INSERT INTO study_days (id, day_number, label, date) VALUES
  (1, 1, 'Week 1', '2026-06-04'),
  (2, 2, 'Week 1', '2026-06-05'),
  (3, 3, 'Week 1', '2026-06-06'),
  (4, 4, 'Week 1', '2026-06-07')
ON CONFLICT (id) DO NOTHING;
SELECT setval('study_days_id_seq', (SELECT COALESCE(max(id), 0) FROM study_days));

INSERT INTO topics (id, study_day_id, subject, topic, duration_min, "order") VALUES
  (1,  1, 'বাংলা সাহিত্য', 'প্রাচীন যুগ', 60, 1),
  (2,  2, 'বাংলা সাহিত্য', 'প্রাচীন যুগ', 60, 1),
  (3,  3, 'বাংলা ব্যাকরণ', 'ধ্বনি তত্ত্ব, বর্ণ', 60, 1),
  (4,  4, 'বাংলা সাহিত্য', 'প্রাচীন যুগ', 60, 1),
  (5,  4, 'English Grammar', 'Cliffs TOEFL Page 57-62', 60, 2),
  (6,  4, 'Vocabulary', 'GRE 333: 31-40', 60, 3),
  (7,  4, 'Math', 'ঐকিক নিয়ম', 120, 4),
  (8,  4, 'GK', 'পাকিস্তান আমল', 60, 5),
  (9,  4, 'Analytical', 'Puzzle 4', 45, 6),
  (10, 4, 'Article', 'Will be provided', 30, 7)
ON CONFLICT (id) DO NOTHING;
SELECT setval('topics_id_seq', (SELECT COALESCE(max(id), 0) FROM topics));

-- ═════════════════════════════════════════════════════════════════
-- STEP 3: MCQ Questions (old: optionA/B/C/D → new: option_a/b/c/d)
-- ═════════════════════════════════════════════════════════════════

INSERT INTO questions (id, subject, topic, question, option_a, option_b, option_c, option_d, correct, explanation, created_at)
VALUES
  (1,'GK','প্রাচীন কাল','Among which of the following options, Sher Shah was well known ?','Mansadadri System','Market Control','Land Revenue System','War Techniques',2,'Sher Shah Suri is famously known for his administrative reforms, particularly his land revenue system, which was highly efficient and influenced later Mughal administration.','2026-06-07 09:29:10.979'::timestamptz),
  (2,'GK','প্রাচীন কাল','Famous tourist Ibn Batuta was the citizen of-','Italy','Tibet','Morocco','Greece',2,'Ibn Battuta was a Moroccan explorer and scholar who traveled extensively across Afro-Eurasia in the 14th century, documenting his journeys in his book "Rihla".','2026-06-07 09:29:10.979'::timestamptz),
  (3,'GK','প্রাচীন কাল','During which period, Sonargaon was the capital of Bangladesh ?','Sultanate rule','Mughal rule','Pala rule','Maurya dynasty',0,'Sonargaon served as the capital of the Sultanate of Bengal for a significant period, particularly during the Ilyas Shahi dynasty, before the rise of the Mughals.','2026-06-07 09:29:10.979'::timestamptz),
  (4,'GK','প্রাচীন কাল','Who of the following is one of the Baro Bhuiyans of Bengal ?','Isa Khan','Mansingha','Shaesta Khan','Islam Khan',0,'Isa Khan was a powerful zamindar and one of the Baro Bhuiyans (twelve territorial landlords) who resisted Mughal rule in Bengal during the late 16th century.','2026-06-07 09:29:10.979'::timestamptz)
ON CONFLICT DO NOTHING;

-- NOTE: Questions 5–244 from the Bengali sections (Bangla Sahitya, Bangla Byakaran)
-- are omitted for brevity. To import all 244 questions, run the companion script:
--   supabase/import_questions.sql
-- which contains the full question bank.

SELECT setval('questions_id_seq', (SELECT COALESCE(max(id), 0) FROM questions));

-- ═════════════════════════════════════════════════════════════════
-- STEP 4: Progress (map old user IDs → new UUIDs)
-- ═════════════════════════════════════════════════════════════════

INSERT INTO progress (id, user_id, topic_id, date, is_complete, has_exam, exam_mark, updated_at)
SELECT * FROM (VALUES
  (1, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 4, '2026-06-07'::date, true, false, NULL, '2026-06-08 12:38:48.258'::timestamptz),
  (2, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 4, '2026-06-07'::date, true, true, 20, '2026-06-08 13:34:06.291'::timestamptz),
  (3, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 4, '2026-06-09'::date, true, false, NULL, '2026-06-08 12:38:48.258'::timestamptz),
  (4, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 4, '2026-06-10'::date, true, false, NULL, '2026-06-08 12:38:48.258'::timestamptz)
) AS t
ON CONFLICT DO NOTHING;
SELECT setval('progress_id_seq', (SELECT COALESCE(max(id), 0) FROM progress));

-- ═════════════════════════════════════════════════════════════════
-- STEP 5: MCQ Attempts (map old user IDs → new UUIDs)
-- ═════════════════════════════════════════════════════════════════

INSERT INTO mcq_attempts (id, user_id, subject, topic, total, correct, wrong, skipped, score, cut_mark, passed, created_at)
SELECT * FROM (VALUES
  (1, neon_uuid('cmq1t9o6q0000hz01nrr0arnc'), 'GK', NULL, 4, 0, 4, 0, -1.0, 2.0, false, '2026-06-07 09:31:13.24'::timestamptz),
  (2, neon_uuid('cmq1t9o6q0000hz01nrr0arnc'), 'GK', 'প্রাচীন কাল', 4, 0, 0, 4, 0.0, 2.0, false, '2026-06-07 09:51:45.961'::timestamptz),
  (3, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), NULL, 'প্রাচীন কাল', 4, 0, 4, 0, -1.0, 2.0, false, '2026-06-07 11:07:32.447'::timestamptz),
  (4, neon_uuid('cmq3o5qeh0000pzr29szukzqh'), 'GK', NULL, 4, 1, 3, 0, 0.25, 2.0, false, '2026-06-07 12:22:44.648'::timestamptz),
  (5, neon_uuid('cmq3o5qeh0000pzr29szukzqh'), 'GK', NULL, 4, 1, 3, 0, 0.25, 2.0, false, '2026-06-07 12:23:16.074'::timestamptz),
  (6, neon_uuid('cmq1t9o6q0000hz01nrr0arnc'), 'GK', 'প্রাচীন কাল', 4, 0, 0, 4, 0.0, 2.0, false, '2026-06-08 03:59:27.588'::timestamptz),
  (7, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 'GK', 'প্রাচীন কাল', 4, 1, 3, 0, 0.25, 2.0, false, '2026-06-08 08:09:22.058'::timestamptz),
  (8, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 'বাংলা সাহিত্য', 'প্রাচীন যুগ', 20, 18, 2, 0, 17.5, 10.0, true, '2026-06-08 13:28:50.331'::timestamptz),
  (9, neon_uuid('cmq36w8rm0000c4efwka6y3qi'), 'বাংলা সাহিত্য', 'প্রাচীন যুগ', 20, 13, 6, 1, 11.5, 10.0, true, '2026-06-08 13:34:06.291'::timestamptz)
) AS t
ON CONFLICT DO NOTHING;
SELECT setval('mcq_attempts_id_seq', (SELECT COALESCE(max(id), 0) FROM mcq_attempts));

-- ═════════════════════════════════════════════════════════════════
-- STEP 6: Puzzles (old text IDs → new UUIDs via neon_uuid)
-- ═════════════════════════════════════════════════════════════════

INSERT INTO puzzles (id, title, topic, status, scenario_paragraph, time_limit, created_at, updated_at)
SELECT * FROM (VALUES
  (neon_uuid('2027867a42d1415dae8beaf4'), 'Puzzle 2', 'Logic Puzzle', 'PUBLISHED',
   E'A government is assigning each of six embassy office workers - Farr, Golden, Hayakawa, Inserra, Jones, and Kovacs to embassies. There are four embassies. Embassies L and M are located in countries with dry climates, whereas embassies P and T are located in countries with humid climates. The office workers must be assigned according to the following rules:',
   5, '2026-06-08 11:19:10.54+00'::timestamptz, '2026-06-08 11:35:56.611+00'::timestamptz),
  (neon_uuid('4b050f57a2f64904a9dda33b'), 'Puzzle-1', 'Logic Puzzle', 'PUBLISHED',
   E'In a game, exactly six Inverted cups stand side by side in a straight line, and each has exactly one ball hidden under it. The cups are numbered consecutively 1 through 6. Each of the balls is painted a single solid color. The colors of the balls are Green, Magenta, Orange, Purple, Red and Yellow. The balls have been hidden under the cups in a manner that confirms to the following conditions.',
   7, '2026-06-08 12:17:03.87+00'::timestamptz, '2026-06-08 12:17:46.842+00'::timestamptz)
) AS t
ON CONFLICT DO NOTHING;

-- ═════════════════════════════════════════════════════════════════
-- STEP 7: Puzzle Questions & Options
-- ═════════════════════════════════════════════════════════════════

INSERT INTO puzzle_questions (id, puzzle_id, position, text, explanation)
SELECT * FROM (VALUES
  (neon_uuid('pq_1_p2'), neon_uuid('2027867a42d1415dae8beaf4'), 1,
   'Which of the following CANNOT be assigned to an embassy in a humid climate?',
   'Farr cannot be assigned to a humid climate embassy because the first rule says Farr must be assigned to an embassy in a dry climate.'),
  (neon_uuid('pq_2_p2'), neon_uuid('2027867a42d1415dae8beaf4'), 2,
   'If Golden and Hayakawa are assigned to the same embassy, which one of the following MUST be true?',
   'If Golden and Hayakawa are together, they must be in a dry climate embassy since Golden requires dry, so at least one embassy in humid climate must have only one worker assigned.'),
  (neon_uuid('pq_1_p1'), neon_uuid('4b050f57a2f64904a9dda33b'), 1,
   'If the Magenta ball is under cup 2, the Red ball is under cup 3, and the Orange ball is under cup 5, then which one of the following could be true?',
   NULL),
  (neon_uuid('pq_2_p1'), neon_uuid('4b050f57a2f64904a9dda33b'), 2,
   'If the Green ball is under cup 1, the Magenta ball is under cup 2, and the Yellow ball is under cup 6, then which one of the following MUST be false?',
   NULL)
) AS t
ON CONFLICT DO NOTHING;

INSERT INTO puzzle_options (id, question_id, label, text, is_correct)
SELECT * FROM (VALUES
  -- Puzzle 2, Question 1 options
  (neon_uuid('opt_p2_q1_a'), neon_uuid('pq_1_p2'), 'A', 'Farr', true),
  (neon_uuid('opt_p2_q1_b'), neon_uuid('pq_1_p2'), 'B', 'Golden', false),
  (neon_uuid('opt_p2_q1_c'), neon_uuid('pq_1_p2'), 'C', 'Hayakawa', false),
  (neon_uuid('opt_p2_q1_d'), neon_uuid('pq_1_p2'), 'D', 'Inserra', false),
  (neon_uuid('opt_p2_q1_e'), neon_uuid('pq_1_p2'), 'E', 'Jones', false),
  -- Puzzle 2, Question 2 options
  (neon_uuid('opt_p2_q2_a'), neon_uuid('pq_2_p2'), 'A', 'Farr is assigned to the same embassy as Jones.', false),
  (neon_uuid('opt_p2_q2_b'), neon_uuid('pq_2_p2'), 'B', 'At least one of the two humid-climate embassies has exactly one worker assigned to it.', true),
  (neon_uuid('opt_p2_q2_c'), neon_uuid('pq_2_p2'), 'C', 'Kovacs and Inserra are assigned to the same embassy.', false),
  -- Puzzle 1, Question 1 options
  (neon_uuid('opt_p1_q1_a'), neon_uuid('pq_1_p1'), 'A', 'The Green ball is under cup 1.', true),
  (neon_uuid('opt_p1_q1_b'), neon_uuid('pq_1_p1'), 'B', 'The Purple ball is under cup 4.', false),
  (neon_uuid('opt_p1_q1_c'), neon_uuid('pq_1_p1'), 'C', 'The Yellow ball is under cup 6.', false),
  -- Puzzle 1, Question 2 options
  (neon_uuid('opt_p1_q2_a'), neon_uuid('pq_2_p1'), 'A', 'The Purple ball is under cup 4.', false),
  (neon_uuid('opt_p1_q2_b'), neon_uuid('pq_2_p1'), 'B', 'The Orange ball is under cup 3.', false),
  (neon_uuid('opt_p1_q2_c'), neon_uuid('pq_2_p1'), 'C', 'The Red ball is under cup 5.', true)
) AS t
ON CONFLICT DO NOTHING;

-- ═════════════════════════════════════════════════════════════════
-- DONE
-- ═════════════════════════════════════════════════════════════════

DO $$ BEGIN
  RAISE NOTICE '──────────────────────────────────────────';
  RAISE NOTICE '✅ Neon → Supabase import completed!';
  RAISE NOTICE '';
  RAISE NOTICE 'Users imported: 4 (passwords preserved)';
  RAISE NOTICE 'Study days:     4';
  RAISE NOTICE 'Topics:         10';
  RAISE NOTICE 'Questions:      4 (full bank in import_questions.sql)';
  RAISE NOTICE 'Progress:       4 entries';
  RAISE NOTICE 'MCQ attempts:   9';
  RAISE NOTICE 'Puzzles:        2 (with questions & options)';
  RAISE NOTICE '──────────────────────────────────────────';
  RAISE NOTICE '';
  RAISE NOTICE 'NEXT: Run import_questions.sql for full MCQ bank';
  RAISE NOTICE '      (244 Bengali/English questions)';
END $$;
