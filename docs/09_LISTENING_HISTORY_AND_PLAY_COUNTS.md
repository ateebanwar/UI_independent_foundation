# YouTube-Style Listening History & Play Count Qualification

## 1. The 5-Second Active Playback Qualification Rule

In streaming audio engineering, recording every button click or track change produces low-quality metrics and frustrates users with false entries. Echo Bloom implements a **YouTube-style playback qualification algorithm**.

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Buffering : User selects track / next queue
    Buffering --> Playing : Audio buffers filled
    note right of Playing : Accumulate elapsed time<br/>(only while status == playing)
    Playing --> Paused : User pauses (accumulation STOPPED)
    Playing --> Seeking : User seeks (accumulation STOPPED)
    Playing --> Playing : Active playback time >= 5s
    note right of Playing : QUALIFIED! Record to SQLite:<br/>1. Insert playback_history<br/>2. Insert listening_sessions<br/>3. Increment play_counts
    Playing --> Idle : Track ends / stopped
```

---

## 2. Qualification Criteria & False-Positive Prevention

A listening event is recorded **if and only if** the track accumulates at least **5 seconds of continuous active playback**:
- **Clicks without playback:** $\text{Active Duration} = 0\text{s} \implies$ **Ignored.**
- **Immediate skips:** User skips after 2 seconds $\implies$ **Ignored.**
- **Buffering & latency:** Time spent waiting for network packets is excluded $\implies$ **Ignored.**
- **Pauses:** Time spent in the paused state is excluded $\implies$ **Ignored.**
- **Seeking:** Leaping across the track does not contribute to accumulated playing time $\implies$ **Ignored.**
- **Active Playback $\ge$ 5s:** Once active playback reaches 5.0 seconds:
  1. Record is inserted into `playback_history`.
  2. Record is inserted into `listening_sessions` with exact session timestamps.
  3. Counter in `play_counts` is atomically incremented by 1.

---

## 3. Database Persistence & Metrics

### 3.1 Sessions Table
```sql
CREATE TABLE listening_sessions (
  id TEXT PRIMARY KEY,
  track_id TEXT NOT NULL,
  session_start INTEGER NOT NULL,
  session_end INTEGER NOT NULL,
  active_playback_seconds INTEGER NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0
);
```

### 3.2 Play Counts Table
```sql
CREATE TABLE play_counts (
  track_id TEXT PRIMARY KEY,
  play_count INTEGER NOT NULL DEFAULT 0,
  last_played_at INTEGER NOT NULL
);
```

---

## 4. History Management APIs

The [`HistoryRepository`](file:///d:/FLutter/redesign%20UI/lib/domain/repositories/history_repository.dart) exposes clean methods for any UI:
- `getRecentHistory({int limit = 50})`: Retrieves chronologically sorted tracks with play timestamps.
- `getPlayCount(String trackId)`: Returns total qualified plays for a track.
- `getLastPlayed(String trackId)`: Returns the most recent qualification timestamp.
- `searchHistory(String query)`: Full-text filter across titles, artists, and albums in history.
- `deleteHistoryItem(int historyId)`: Removes an individual record.
- `clearHistory()`: Truncates user history and active session data safely.

---

## 5. Verification Evidence

Verified in `test/features/history/youtube_history_qualification_test.dart`:
- `Clicking or starting a song without playback does NOT qualify or create history` $\to$ **Passed**
- `Playback lasting less than threshold (e.g. 3 seconds) does NOT qualify` $\to$ **Passed**
- `Playback reaching 5-second threshold creates history with full metadata and increments play count` $\to$ **Passed**
- `Pausing halts accumulation; resumed playback reaches threshold and qualifies` $\to$ **Passed**
- `Buffering duration is excluded from active listening accumulation` $\to$ **Passed**
- `Seeking resets or maintains active playback correctly without false qualification` $\to$ **Passed**
- `Deleting individual history item and searching history works accurately` $\to$ **Passed**
- `Clear history safely removes all sessions and resets records` $\to$ **Passed**
