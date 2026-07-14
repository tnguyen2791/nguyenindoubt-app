One row of a settings group: label + optional description on the left, value/chevron or Toggle on the right. Stack inside a Card; rows draw their own hairline top border — pass `first` on the first row to suppress it.

```jsx
<Card>
  <SettingsRow first label="Morning reading" description="One note when your scores are ready" control="toggle" on />
  <SettingsRow label="Bedtime window" value="10:30–11:30p" />
</Card>
```
