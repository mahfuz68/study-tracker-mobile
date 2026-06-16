-- Study Progress Tracker - Supabase Schema
-- Run this in your Supabase SQL Editor to create all tables
-- Auth is handled by Supabase Auth (built-in)
-- All statements are idempotent (safe to re-run)

-- 1. Profiles table (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
  share_token TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'USER')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. Study Days
CREATE TABLE IF NOT EXISTS study_days (
  id SERIAL PRIMARY KEY,
  day_number INT NOT NULL UNIQUE,
  label TEXT,
  date DATE
);

ALTER TABLE study_days ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Study days readable by all authenticated" ON study_days;
CREATE POLICY "Study days readable by all authenticated"
  ON study_days FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Topics
CREATE TABLE IF NOT EXISTS topics (
  id SERIAL PRIMARY KEY,
  study_day_id INT NOT NULL REFERENCES study_days(id),
  subject TEXT NOT NULL,
  topic TEXT NOT NULL,
  duration_min INT NOT NULL DEFAULT 0,
  "order" INT NOT NULL DEFAULT 0
);

ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Topics readable by all authenticated" ON topics;
CREATE POLICY "Topics readable by all authenticated"
  ON topics FOR SELECT USING (auth.role() = 'authenticated');

-- 4. Progress
CREATE TABLE IF NOT EXISTS progress (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id),
  topic_id INT NOT NULL REFERENCES topics(id),
  date DATE NOT NULL,
  is_complete BOOLEAN NOT NULL DEFAULT FALSE,
  has_exam BOOLEAN NOT NULL DEFAULT FALSE,
  exam_mark INT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, topic_id, date)
);

ALTER TABLE progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own progress" ON progress;
CREATE POLICY "Users manage own progress"
  ON progress FOR ALL USING (auth.uid() = user_id);

-- 5. Topic Exams
CREATE TABLE IF NOT EXISTS topic_exams (
  id SERIAL PRIMARY KEY,
  topic_id INT NOT NULL UNIQUE REFERENCES topics(id) ON DELETE CASCADE,
  name TEXT,
  total_marks INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE topic_exams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Topic exams readable by all authenticated" ON topic_exams;
CREATE POLICY "Topic exams readable by all authenticated"
  ON topic_exams FOR SELECT USING (auth.role() = 'authenticated');

-- 6. Questions (MCQ Bank)
CREATE TABLE IF NOT EXISTS questions (
  id SERIAL PRIMARY KEY,
  subject TEXT NOT NULL,
  topic TEXT NOT NULL,
  question TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  option_d TEXT NOT NULL,
  correct INT NOT NULL CHECK (correct >= 0 AND correct <= 3),
  explanation TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Questions readable by all authenticated" ON questions;
CREATE POLICY "Questions readable by all authenticated"
  ON questions FOR SELECT USING (auth.role() = 'authenticated');

-- 7. MCQ Attempts
CREATE TABLE IF NOT EXISTS mcq_attempts (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id),
  subject TEXT,
  topic TEXT,
  total INT NOT NULL,
  correct INT NOT NULL DEFAULT 0,
  wrong INT NOT NULL DEFAULT 0,
  skipped INT NOT NULL DEFAULT 0,
  score DOUBLE PRECISION NOT NULL DEFAULT 0,
  cut_mark DOUBLE PRECISION NOT NULL DEFAULT 0,
  passed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE mcq_attempts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own attempts" ON mcq_attempts;
CREATE POLICY "Users manage own attempts"
  ON mcq_attempts FOR ALL USING (auth.uid() = user_id);

-- 8. MCQ Answers
CREATE TABLE IF NOT EXISTS mcq_answers (
  id SERIAL PRIMARY KEY,
  attempt_id INT NOT NULL REFERENCES mcq_attempts(id),
  question_id INT NOT NULL REFERENCES questions(id),
  chosen INT,
  is_correct BOOLEAN
);

ALTER TABLE mcq_answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Answers readable via attempt owner" ON mcq_answers;
CREATE POLICY "Answers readable via attempt owner"
  ON mcq_answers FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM mcq_attempts
      WHERE mcq_attempts.id = mcq_answers.attempt_id
      AND mcq_attempts.user_id = auth.uid()
    )
  );

-- 9. Puzzles
CREATE TABLE IF NOT EXISTS puzzles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  topic TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED')),
  scenario_paragraph TEXT NOT NULL,
  time_limit INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE puzzles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Published puzzles readable by all" ON puzzles;
CREATE POLICY "Published puzzles readable by all"
  ON puzzles FOR SELECT USING (status = 'PUBLISHED');

-- 10. Puzzle Extras
CREATE TABLE IF NOT EXISTS puzzle_extras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_id UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('BULLETS', 'TABLE')),
  position INT NOT NULL DEFAULT 0,
  content JSONB NOT NULL DEFAULT '{}'
);

ALTER TABLE puzzle_extras ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Extras readable via puzzle" ON puzzle_extras;
CREATE POLICY "Extras readable via puzzle"
  ON puzzle_extras FOR SELECT USING (
    EXISTS (SELECT 1 FROM puzzles WHERE puzzles.id = puzzle_extras.puzzle_id)
  );

-- 11. Puzzle Questions
CREATE TABLE IF NOT EXISTS puzzle_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_id UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  position INT NOT NULL,
  text TEXT NOT NULL,
  explanation TEXT
);

ALTER TABLE puzzle_questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Questions readable via puzzle" ON puzzle_questions;
CREATE POLICY "Questions readable via puzzle"
  ON puzzle_questions FOR SELECT USING (
    EXISTS (SELECT 1 FROM puzzles WHERE puzzles.id = puzzle_questions.puzzle_id)
  );

-- 12. Puzzle Options
CREATE TABLE IF NOT EXISTS puzzle_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES puzzle_questions(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  text TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE puzzle_options ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Options readable via question" ON puzzle_options;
CREATE POLICY "Options readable via question"
  ON puzzle_options FOR SELECT USING (
    EXISTS (SELECT 1 FROM puzzle_questions WHERE puzzle_questions.id = puzzle_options.question_id)
  );

-- 13. Puzzle Attempts
CREATE TABLE IF NOT EXISTS puzzle_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_id UUID NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  total INT NOT NULL DEFAULT 0,
  correct INT NOT NULL DEFAULT 0,
  wrong INT NOT NULL DEFAULT 0,
  skipped INT NOT NULL DEFAULT 0,
  score DOUBLE PRECISION,
  passed BOOLEAN
);

ALTER TABLE puzzle_attempts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own puzzle attempts" ON puzzle_attempts;
CREATE POLICY "Users manage own puzzle attempts"
  ON puzzle_attempts FOR ALL USING (auth.uid() = user_id);

-- 14. Puzzle Answers
CREATE TABLE IF NOT EXISTS puzzle_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id UUID NOT NULL REFERENCES puzzle_attempts(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES puzzle_questions(id),
  selected_option_id UUID
);

ALTER TABLE puzzle_answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Answers readable via attempt owner" ON puzzle_answers;
CREATE POLICY "Answers readable via attempt owner"
  ON puzzle_answers FOR SELECT USING (
    EXISTS (SELECT 1 FROM puzzle_attempts
      WHERE puzzle_attempts.id = puzzle_answers.attempt_id
      AND puzzle_attempts.user_id = auth.uid())
  );

-- Seed data: sample study days and topics
INSERT INTO study_days (day_number, label) VALUES
  (1, 'Week 1'),
  (2, 'Week 2'),
  (3, 'Week 3'),
  (4, 'Week 4')
ON CONFLICT DO NOTHING;

INSERT INTO topics (study_day_id, subject, topic, duration_min, "order") VALUES
  (1, 'Bangla', 'বাস্তব সংখ্যা', 45, 1),
  (1, 'English', 'Grammar', 30, 2),
  (1, 'Vocabulary', 'Word List 1', 20, 3),
  (1, 'Math', 'Algebra', 60, 4),
  (2, 'English', 'Comprehension', 35, 1),
  (2, 'GK', 'Bangladesh Affairs', 40, 2),
  (2, 'Math', 'Geometry', 50, 3),
  (2, 'Analytical', 'Puzzle Solving', 30, 4),
  (3, 'Bangla', 'সাহিত্য', 45, 1),
  (3, 'English', 'Vocabulary', 25, 2),
  (3, 'GK', 'International Affairs', 40, 3),
  (3, 'Article', 'Writing Practice', 35, 4),
  (4, 'Math', 'Trigonometry', 55, 1),
  (4, 'Analytical', 'Data Interpretation', 35, 2),
  (4, 'English', 'Grammar Rules', 30, 3),
  (4, 'Bangla', 'প্রবন্ধ রচনা', 40, 4)
ON CONFLICT DO NOTHING;
