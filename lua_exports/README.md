# Lua Exports

Production export scripts executed inside Live Editor while Career Mode is active. Each script writes a CSV to the user's Desktop using the filename convention described in `PLAN_TECHNIQUE.md` §13.3:

```
<KIND>_DD_MM_YYYY.csv
```

Outputs land in `%USERPROFILE%\Desktop`. The Python app imports them from there.
