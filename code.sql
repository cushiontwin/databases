CREATE TABLE Feature (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32)
);

CREATE TABLE Instructor (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(32),
    email VARCHAR(32)
);

CREATE TABLE Course (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(64),
    instructor_id INT,
    FOREIGN KEY (instructor_id) REFERENCES Instructor(id),
    INDEX courseNameIDX (name)
);

CREATE TABLE Room (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(64),
    capacity INT

);

CREATE TABLE TimeSlot (
  id INT PRIMARY KEY AUTO_INCREMENT,
  start_time DATETIME,
  end_time DATETIME,
  INDEX timeSlotRange (start_time, end_time) -- Allows fast date range filtering
);

CREATE TABLE Booking (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT,
    room_id INT,
    timeslot_id INT,
    FOREIGN KEY (course_id) REFERENCES Course(id),
    FOREIGN KEY (room_id) REFERENCES Room(id),
    FOREIGN KEY (timeslot_id) REFERENCES TimeSlot(id),
    UNIQUE (room_id, timeslot_id),
    INDEX room_by_timeslot (room_id, timeslot_id), -- Allows fast availability queries
    INDEX room_by_course (room_id, course_id)
);


-- Junction Tables 
CREATE TABLE CourseFeature (
    course_id INT,
    feature_id INT,
    PRIMARY KEY (course_id, feature_id),
    FOREIGN KEY (course_id) REFERENCES Course(id),
    FOREIGN KEY (feature_id) REFERENCES Feature(id)
);

CREATE TABLE RoomFeature (
    room_id INT,
    feature_id INT,
    capacity INT DEFAULT 0,
    PRIMARY KEY (room_id, feature_id),
    FOREIGN KEY (room_id) REFERENCES Room(id),
    FOREIGN KEY (feature_id) REFERENCES Feature(id)
);


-- FILLER
INSERT INTO Instructor (name, email) VALUES
('Alice Smith', 'alice@example.com'),
('Bob Johnson', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com'),
('Diana Green', 'diana@example.com'),
('Ethan White', 'ethan@example.com');

INSERT INTO Feature (name) VALUES 
('Projector'),
('Computer'),
('Whiteboard'),
('Networking Servers'),
('Analog Electronics');

INSERT INTO Course (name, instructor_id) VALUES
('Math 101', 1),
('Physics 201', 2),
('Chemistry 301', 3),
('Biology 101', 4),
('Computer Science 101', 5),
('Computer Science 101', 5),
('History 101', 1),
('English 201', 2),
('Art 101', 3),
('Music 101', 4),
('Economics 101', 5);


INSERT INTO Room (name, capacity)
SELECT CONCAT('Room ', n), 
       20 + (n % 5) * 5
FROM (
  SELECT ROW_NUMBER() OVER () AS n
  FROM information_schema.columns
  LIMIT 5
) AS numbers;


INSERT INTO RoomFeature (room_id, feature_id)
VALUES (1, 1),
       (1, 2),
       
       (2, 2),
       (2, 3), 
       
       (3, 1),  
       (3, 4),  
       
       (4, 1),
       (4, 2),
       (4, 3);

INSERT INTO CourseFeature (course_id, feature_id)
VALUES (1, 1), 
       (1, 2),  
       
       (2, 2),  
       (2, 3),  
       
       (3, 1),  
       (3, 3),  
       
       (4, 1),
       (4, 2);


-- DELIMITER $$
-- CREATE PROCEDURE PopulateTimeSlots(
--   IN start_date DATE,
--   IN end_date DATE,
--   IN start_hour INT,
--   IN end_hour INT
-- )
-- BEGIN
--     DECLARE current_day DATE;
--     DECLARE current_hour INT;

--     SET current_day = start_date;

--     WHILE current_day <= end_date DO
--         SET current_hour = start_hour;

--         WHILE current_hour <= end_hour DO
--             INSERT INTO TimeSlot (start_time, end_time)
--             VALUES (
--                 DATE_ADD(current_day, INTERVAL current_hour HOUR),
--                 DATE_ADD(current_day, INTERVAL current_hour + 1 HOUR)
--             );
--             SET current_hour = current_hour + 1;
--         END WHILE;

--         SET current_day = DATE_ADD(current_day, INTERVAL 1 DAY);
--     END WHILE;
-- END$$
-- DELIMITER ;

DELIMITER $$
CREATE PROCEDURE FillBookingRandomly(IN num INT)
BEGIN
    DECLARE total_courses INT;

    -- Count courses once
    SELECT COUNT(*) INTO total_courses FROM Course;

    -- Insert random bookings into Booking table
    INSERT INTO Booking (course_id, room_id, timeslot_id)
    SELECT 
        FLOOR(1 + RAND() * total_courses) AS course_id,
        room_id,
        timeslot_id
    FROM (
        -- CTE for all available room × timeslot combinations
        SELECT r.id AS room_id, ts.id AS timeslot_id
        FROM Room r
        JOIN TimeSlot ts
        LEFT JOIN Booking b
            ON b.room_id = r.id AND b.timeslot_id = ts.id
        WHERE b.id IS NULL
        ORDER BY RAND()
        LIMIT num
    ) AS available;
END$$

DELIMITER ;




-- University Room Booking Database
-- Nov 5, 2025 17:00


-- CALL PopulateTimeSlots('2025-01-01', '2025-06-01', 9, 16);
INSERT INTO TimeSlot (start_time, end_time) VALUES
  ('2025-01-01 09:00:00', '2025-01-01 10:00:00'),
  ('2025-01-01 10:00:00', '2025-01-01 11:00:00'),
  ('2025-01-01 11:00:00', '2025-01-01 12:00:00'),
  ('2025-01-01 12:00:00', '2025-01-01 13:00:00'),
  ('2025-01-01 13:00:00', '2025-01-01 14:00:00'),
  ('2025-01-01 14:00:00', '2025-01-01 15:00:00'),
  ('2025-01-01 15:00:00', '2025-01-01 16:00:00');

INSERT INTO Booking (course_id, room_id, timeslot_id) VALUES
  (4, 4, 1),
  (1, 1, 2),
  (1, 1, 3),
  (3, 2, 3);

-- CALL FillBookingRandomly(10);
select * from booking;

SET @room_id = null;           -- NULL = any room
SET @min_capacity = 25;        -- only rooms with at least this capacity
SET @start = '2025-01-01 9:00:00';
SET @end = '2025-01-01 11:00:00';
SET @course_name = 'Computer Science 101';       -- NULL = any coursea
SET @course_id = null;       -- NULL = any coursea


-- SELECT * FROM Booking ORDER BY timeslot_id;
-- SELECT * FROM RoomFeature ORDER BY room_id;
-- SELECT * FROM CourseFeature ORDER BY course_id;


-- SET PROFILING = 1;

WITH RoomsWithAllFeatures AS (
  -- Retrieve rooms that have all/more of the same features as a course.
  SELECT rf.room_id
    FROM RoomFeature rf
    
   INNER JOIN CourseFeature cf
      ON cf.feature_id = rf.feature_id
      
   WHERE (@course_id IS NULL OR cf.course_id = @course_id)
   GROUP BY rf.room_id
  
  HAVING (@course_id IS NULL)  -- If no course_id, ignore feature count
      OR COUNT(*) = ( -- Ensures that at minimum, all features required are present
      SELECT COUNT(feature_id) 
        FROM CourseFeature 
       WHERE course_id = @course_id
    -- AND (@room_id IS NULL OR rf.room_id = @room_id)
  )
)
SELECT r.id, ts.id AS timeslot_id, ts.start_time, ts.end_time
-- SELECT
  FROM RoomsWithAllFeatures rwf 
  
-- Joins every timeslot to each room_id and filters out timeslots
-- outside the range specified.
    
  INNER JOIN Room r
     ON r.id = rwf.room_id
  -- AND (@min_capacity IS NULL OR r.capacity >= @min_capacity)
    
 CROSS JOIN (
    SELECT id, start_time, end_time
      FROM TimeSlot
     WHERE start_time < @end
       AND end_time > @start
) AS ts

-- Filters out conflicting timeslots from Booking
  LEFT JOIN Booking b
    ON b.room_id = rwf.room_id
   AND b.timeslot_id = ts.id
   
  
 WHERE b.id IS NULL
   AND (@room_id IS NULL OR r.id = @room_id)
   AND (@min_capacity IS NULL OR r.capacity >= @min_capacity)
 ORDER BY rwf.room_id, ts.id;
 

-- SHOW PROFILES;






