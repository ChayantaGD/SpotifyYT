-- SQL project with Dataset which includes Spotify and Youtube Statistics for the Songs of Various Artists

-- Creating the table

DROP TABLE IF EXISTS spotifyYT;
CREATE TABLE spotifyYT (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

-- Exploratory Data Analysis (EDA)

SELECT COUNT(*) FROM SpotifyYT;

SELECT COUNT(DISTINCT artist) AS no_of_artists, COUNT(DISTINCT album) AS no_of_albums FROM SpotifyYT;

SELECT DISTINCT album_type, channel, most_played_on FROM SpotifyYT;

SELECT MAX(duration_min), MIN(duration_min), AVG(duration_min) FROM SpotifyYT; -- We see minimum duration is zero which cannot be,so we will eliminate those rows

DELETE FROM SpotifyYT
WHERE duration_min = 0; 

--Retrieving the names of all tracks that have more than 1 billion streams

SELECT track from SpotifyYT
WHERE stream> 1000000000;

--Listing all albums along with their respective artists

SELECT DISTINCT album, artist 
from SpotifyYT
ORDER BY 1;

-- Finding total number of comments for licensed tracks

SELECT SUM(comments) 
FROM SpotifyYT
WHERE licensed = 'TRUE';

--Counting the total number of tracks by each artist

SELECT artist, 
COUNT (track) Total_tracks_by_artist
FROM SpotifyYT
GROUP BY artist
ORDER BY 2;

-- Calculating the average danceability of tracks

SELECT track, 
AVG(danceability) Average_Danceability_Score
FROM SpotifyYT
GROUP BY 1;

--Finding the top 5 tracks with the highest energy values

SELECT track, energy
FROM SpotifyYT
ORDER BY energy DESC
LIMIT 5;

--Listing all tracks with an official video along with their views and likes

SELECT track, 
SUM(views) total_views, 
SUM(likes) total_likes 
FROM SpotifyYT
WHERE official_video = 'TRUE'
GROUP BY track;


--Calculating the total views of all associated tracks and their album

SELECT album,
track,
SUM(VIEWS) total_views
FROM SpotifyYT
GROUP BY 1,2;

--Retrieving the track names thatwhere the number of Spotify streams is more than YouTube

SELECT * FROM
(SELECT track,
COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS Streamed_on_Spotify,
COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN  stream END),0) AS Streamed_on_YouTube
FROM SpotifyYT
GROUP BY track) spyt1
WHERE Streamed_on_Spotify > Streamed_on_YouTube
AND
Streamed_on_YouTube != 0;

--Finding tracks where the energy-to-liveness ratio is greater than 5

SELECT 
    track,
    artist,
    album,
    energy,
    liveness,
    CAST((energy / liveness) AS DECIMAL(10,2)) AS energy_liveness_ratio
FROM 
    SpotifyYT
WHERE 
    liveness > 0  -- Prevent division by zero
    AND (energy / liveness) > 5
ORDER BY 
    energy_liveness_ratio DESC;

--Calculating the cumulative sum of likes for tracks ordered by the number of views, using window functions

SELECT 
    track,
    artist,
    views,
    likes,
    SUM(likes) OVER (ORDER BY views DESC) AS cumulative_likes
FROM 
    SpotifyYT
ORDER BY 
    views DESC;
	
--Finding the top 3 most-viewed tracks for each artist using window functions and CTE

WITH ranked_tracks AS (
    SELECT 
        artist, 
        track,
        SUM(VIEWS) AS total_views,
        DENSE_RANK() OVER (
            PARTITION BY artist
            ORDER BY SUM(VIEWS) DESC
        ) AS Top_Tracks_By_Artist_Ranked
    FROM SpotifyYT
    GROUP BY artist, track
)
SELECT *
FROM ranked_tracks
WHERE Top_Tracks_By_Artist_Ranked <= 3;

--Finding tracks where the acousticness score is above the average

WITH Avg_Acoustic AS (
    SELECT AVG(acousticness) AS Avg_Acoustic_score
    FROM SpotifyYT
)
SELECT 
    SYT.track, 
    SYT.acousticness,
    Avg_Acoustic.Avg_Acoustic_score
FROM SpotifyYT AS SYT
CROSS JOIN Avg_Acoustic
WHERE SYT.acousticness > Avg_Acoustic.Avg_Acoustic_score
ORDER BY SYT.acousticness DESC;

--Calculating the difference between the highest and lowest energy values for tracks in each album

WITH cte AS (
SELECT album, 
MAX(energy) AS Max_Energy_Score,
MIN (energy) AS Min_Energy_Score
FROM SpotifyYT
GROUP BY album
)
SELECT album,
Max_Energy_Score - Min_Energy_Score AS Energy_Score_Difference
FROM cte
ORDER BY Energy_Score_Difference DESC;

--IIdentifying top-performing artists

WITH artist_performance AS (
    SELECT 
        artist,
        SUM(stream) AS total_streams,
        SUM(views) AS total_views,
        SUM(likes) AS total_likes,
        SUM(comments) AS total_comments,
        ROW_NUMBER() OVER (ORDER BY SUM(stream) DESC) AS stream_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(views) DESC) AS view_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(likes) DESC) AS like_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(comments) DESC) AS comment_rank
    FROM 
        SpotifyYT
    GROUP BY 
        artist
)
SELECT 
    artist,
    total_streams,
    total_views,
    total_likes,
    total_comments,
    stream_rank,
    view_rank,
    like_rank,
    comment_rank
FROM 
    artist_performance
WHERE 
    stream_rank <= 10 OR view_rank <= 10 OR like_rank <= 10 OR comment_rank <= 10
ORDER BY 
    stream_rank, view_rank;

-- Spotify vs Youtube Comparison

WITH platform_comparison AS (
    SELECT 
        artist,
        track,
        stream AS spotify_streams,
        views AS youtube_views,
        CASE 
            WHEN stream > views THEN 'Spotify'
            WHEN views > stream THEN 'YouTube'
            ELSE 'Equal'
        END AS better_performing_platform,
        (stream - views) AS performance_difference
    FROM 
        SpotifyYT
)
SELECT 
    artist,
    track,
    spotify_streams,
    youtube_views,
    better_performing_platform,
    ABS(performance_difference) AS performance_difference,
    (CASE 
        WHEN better_performing_platform = 'Spotify' 
        THEN (spotify_streams::float / NULLIF(youtube_views, 0)) 
        ELSE (youtube_views::float / NULLIF(spotify_streams, 0)) 
    END, 2) AS performance_ratio
FROM 
    platform_comparison
ORDER BY 
    performance_difference DESC, performance_ratio DESC;

-- Querry Optimiaztion

EXPLAIN ANALYZE 
SELECT artist,
track,
album
FROM SpotifyYT 
WHERE artist = 'The Weeknd'
AND
Duration_min > 4
ORDER BY stream desc; 

CREATE INDEX artist_index ON SpotifyYT(artist);

	


