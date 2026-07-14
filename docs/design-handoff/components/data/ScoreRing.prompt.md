The signature 0–100 ring: mint track, rounded state-colored arc, big number + quiet caption in the center.

```jsx
<ScoreRing score={82} label="balanced" color="var(--state-optimal)" />
<ScoreRing score={95} label="quality" size={104} strokeWidth={11} />
```

Color encodes state: --state-optimal / good / fair / attention. One ring per metric.
