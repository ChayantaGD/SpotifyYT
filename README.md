# Comprehensive Music Streaming Analytics: Spotify & YouTube

![spotifyYt](https://github.com/user-attachments/assets/fd17a6f2-c646-45e7-b540-2e7c4859da8b)

## Overview
This project analyzes a dataset containing statistics for tracks, artists, and albums on Spotify and YouTube. The data includes attributes like danceability, acoustic scores, streams, views, likes, and comments. The project involves running SQL queries across various difficulty levels to generate insights into track performance, artist popularity, and platform-specific engagement. 

## Project Steps

### Data Exploration
Before diving into SQL, it’s important to understand the dataset thoroughly. The dataset contains attributes such as:
- `Artist`: The performer of the track.
- `Track`: The name of the song.
- `Album`: The album to which the track belongs.
- `Album_type`: The type of album (e.g., single or album).
- Various metrics such as `danceability`, `energy`, `loudness`, `tempo`, and more
  
###  Querying the Data

Basic queries to retrieve top tracks and album statistics.

Retrieving the names of all tracks that have more than 1 billion streams

```sql
SELECT track from SpotifyYT
WHERE stream> 1000000000;
```

Listing all albums along with their respective artists

```sql
SELECT DISTINCT album, artist 
from SpotifyYT
ORDER BY 1;
```
Finding total number of comments for licensed tracks

```sql
SELECT SUM(comments) 
FROM SpotifyYT
WHERE licensed = 'TRUE';
```

Counting the total number of tracks by each artist

```sql
SELECT artist, 
COUNT (track) Total_tracks_by_artist
FROM SpotifyYT
GROUP BY artist
ORDER BY 2;
```

Medium-level queries to calculate average scores, compare platform performance, and track official video engagement.

Calculating the average danceability of tracks

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


Calculating the total views of all associated tracks and their album

```sql
SELECT album,
track,
SUM(VIEWS) total_views
FROM SpotifyYT
GROUP BY 1,2;
```

etrieving the track names thatwhere the number of Spotify streams is more than YouTube

```sql
SELECT * FROM
(SELECT track,
COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS Streamed_on_Spotify,
COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN  stream END),0) AS Streamed_on_YouTube
FROM SpotifyYT
GROUP BY track) spyt1
WHERE Streamed_on_Spotify > Streamed_on_YouTube
AND
Streamed_on_YouTube != 0;
```

Finding tracks where the energy-to-liveness ratio is greater than 5

```sql
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
```

Calculating the cumulative sum of likes for tracks ordered by the number of views, using window functions

```sql
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
```

Advanced-level queries using window functions to find top-viewed tracks, calculate cumulative sums, and analyze energy-to-liveness ratios, also including an in-depth comparison of Spotify and YouTube performance for artists and tracks, offering valuable insights for optimizing promotional strategies.

Finding the top 3 most-viewed tracks for each artist using window functions and CTE

```sql
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
```

Finding tracks where the acousticness score is above the average

```sql
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
```

Calculating the difference between the highest and lowest energy values for tracks in each album

```sql
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
```

Identifying top-performing artists

```sql
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
```

Spotify vs Youtube Comparison

```sql
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
```

## Querry Optimization

- **Initial Query Performance Analysis Using `EXPLAIN`**
    - We began by analyzing the performance of a query using the `EXPLAIN` function.
    - The query retrieved tracks based on the `artist` column, and the performance metrics were as follows:
        - Execution time (E.T.): **2.6 ms**
        - Planning time (P.T.): **0.86 ms**
    - Below is the **screenshot** of the `EXPLAIN` result before optimization:

![dssb4](https://github.com/user-attachments/assets/b750d4a7-c3f6-4c30-b7a5-25e74a65a019)

- **Index Creation on the `artist` Column**
    - To optimize the query performance, we created an index on the `artist` column. This ensures faster retrieval of rows where the artist is queried.
    - **SQL command** for creating the index:
      ```sql
      CREATE INDEX artist_index ON SpotifyYT(artist);
      ```

- **Performance Analysis After Index Creation**
    - After creating the index, we ran the same query again and observed significant improvements in performance:
        - Execution time (E.T.): **1.5 ms**
        - Planning time (P.T.): **0.07 ms**
    - Below is the **screenshot** of the `EXPLAIN` result after index creation:      

![dssa4](https://github.com/user-attachments/assets/c2fb3bcb-fe72-4f9d-8131-b3461980ee1f)

This optimization shows how indexing can drastically reduce query time, improving the overall performance of our database operations in the Spotify project.
---

## Technology Stack
- **Database**: PostgreSQL
- **SQL Queries**: DDL, DML, Aggregations, Joins, Subqueries, Window Functions
- **Tools**: pgAdmin 4 (or any SQL editor), PostgreSQL (via Homebrew, Docker, or direct installation)

## How to Run the Project
1. Install PostgreSQL and pgAdmin (if not already installed).
2. Set up the database schema and tables using the provided normalization structure.
3. Insert the sample data into the respective tables.
4. Execute SQL queries to solve the listed problems.
5. Explore query optimization techniques for large datasets.

---

## Next Steps
- **Visualize the Data**: Use a data visualization tool like **Tableau** or **Power BI** to create dashboards based on the query results.
- **Expand Dataset**: Add more rows to the dataset for broader analysis and scalability testing.
- **Advanced Querying**: Dive deeper into query optimization and explore the performance of SQL queries on larger datasets.

---

This project highlights skills in data cleaning, transformation, and advanced SQL queries, making it an ideal portfolio project for aspiring data analysts.
