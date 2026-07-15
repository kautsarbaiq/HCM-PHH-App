-- HCA parking follow-up (boss feedback 15/07): the resident's car is captured
-- as structured fields instead of one free-text blob. `vehicle_details` stays
-- for backward compatibility (old rows still display); new saves write the
-- structured columns. HCA database only.

ALTER TABLE public.parking_bays
  ADD COLUMN IF NOT EXISTS vehicle_make  text,
  ADD COLUMN IF NOT EXISTS vehicle_model text,
  ADD COLUMN IF NOT EXISTS vehicle_year  text,
  ADD COLUMN IF NOT EXISTS vehicle_color text;
