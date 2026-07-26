import pandas as pd
import numpy as np
import re

df = pd.read_csv("nigeria_rainfall_flood_planning_dirty.csv", dtype=str, keep_default_na=False,
                  on_bad_lines="warn", engine="python")

before_rows = len(df)

# 1. Drop fully blank rows
df = df[~(df.apply(lambda r: all(str(v).strip()=="" for v in r), axis=1))]

# 2. Drop exact duplicate rows
df = df.drop_duplicates()

# 3. Drop malformed rows (wrong column count already coerced by pandas on read;
#    but our injected malformed rows have fewer/extra fields -> they show up as NaN-heavy or misaligned)
#    Identify by checking State is a known value and Date parses; else drop.
valid_states = {"Lagos","Rivers","Bayelsa","Delta","Akwa Ibom","Cross River","Anambra",
                 "Kogi","Benue","Niger","Kano","Kaduna","Sokoto","Borno","Plateau"}

def clean_state(s):
    s = str(s).strip()
    s = re.sub(r'\s+', ' ', s)
    s = s.title()
    fixes = {"Akwaibom":"Akwa Ibom", "Akwa-Ibom":"Akwa Ibom"}
    return fixes.get(s, s)

df["State"] = df["State"].apply(clean_state)
df = df[df["State"].isin(valid_states)]

# 4. Parse dates (mixed formats)
def parse_date(s):
    s = str(s).strip()
    for fmt in ("%Y-%m-%d","%d/%m/%Y","%m-%d-%Y","%d-%b-%Y","%Y/%m","%b-%Y"):
        try:
            d = pd.to_datetime(s, format=fmt)
            return d
        except ValueError:
            continue
    return pd.NaT

df["Date_Clean"] = df["Date"].apply(parse_date)
unparsed = df["Date_Clean"].isna().sum()
df = df.dropna(subset=["Date_Clean"])
df["Year"] = df["Date_Clean"].dt.year
df["Month"] = df["Date_Clean"].dt.month

# 5. Clean Rainfall_Amount + Unit -> unify to mm
def to_num(x):
    x = str(x).strip()
    if x in ("", "N/A", "NA", "n/a"):
        return np.nan
    try:
        return float(x)
    except ValueError:
        return np.nan

df["Rainfall_mm"] = df["Rainfall_Amount"].apply(to_num)
df.loc[(df["Rainfall_mm"] < 0) | (df["Rainfall_mm"] == 9999), "Rainfall_mm"] = np.nan

unit_clean = df["Unit"].astype(str).str.strip().str.lower()
is_cm = unit_clean.eq("cm")
df.loc[is_cm, "Rainfall_mm"] = df.loc[is_cm, "Rainfall_mm"] * 10

# 6. Flood_Occurred -> boolean
yes_set = {"YES","Y","1","TRUE"}
df["Flood_Occurred_Clean"] = df["Flood_Occurred"].astype(str).str.strip().str.upper().isin(yes_set)

# 7. Flood_Severity -> standardized
def clean_sev(s, occurred):
    s = str(s).strip().title()
    if s in ("", "None", "none", "Non"):
        s = "None"
    if not occurred:
        return "None"
    if s == "None":
        return np.nan  # occurred but severity missing -> needs review
    return s

df["Flood_Severity_Clean"] = [clean_sev(s,o) for s,o in zip(df["Flood_Severity"], df["Flood_Occurred_Clean"])]

# 8. Affected_LGAs -> numeric, 0 where no flood
df["Affected_LGAs_Clean"] = pd.to_numeric(df["Affected_LGAs"], errors="coerce")
df.loc[(~df["Flood_Occurred_Clean"]) & (df["Affected_LGAs_Clean"].isna()), "Affected_LGAs_Clean"] = 0

# 9. Persons_Displaced -> strip commas, numeric
df["Persons_Displaced_Clean"] = pd.to_numeric(
    df["Persons_Displaced"].astype(str).str.replace(",", "", regex=False), errors="coerce"
)
df.loc[(~df["Flood_Occurred_Clean"]) & (df["Persons_Displaced_Clean"].isna()), "Persons_Displaced_Clean"] = 0

# 10. Casualties -> numeric, "unknown" -> NaN
df["Casualties_Clean"] = pd.to_numeric(df["Casualties"].replace("unknown", np.nan), errors="coerce")
df.loc[(~df["Flood_Occurred_Clean"]) & (df["Casualties_Clean"].isna()), "Casualties_Clean"] = 0

# 11. Economic_Loss -> parse currency symbol / commas / "M" shorthand
def parse_loss(x):
    x = str(x).strip()
    if x == "":
        return np.nan
    x = x.replace("₦", "").replace(",", "")
    if x.upper().endswith("M"):
        try:
            return float(x[:-1]) * 1_000_000
        except ValueError:
            return np.nan
    try:
        return float(x)
    except ValueError:
        return np.nan

df["Economic_Loss_Clean"] = df["Economic_Loss"].apply(parse_loss)
df.loc[(~df["Flood_Occurred_Clean"]) & (df["Economic_Loss_Clean"].isna()), "Economic_Loss_Clean"] = 0

# 12. Data_Source -> standardized
def clean_source(s):
    s = str(s).strip().title()
    return s if s else "Unspecified"
df["Data_Source_Clean"] = df["Data_Source"].apply(clean_source)

# Final clean table
clean = df[["State","Date_Clean","Year","Month","Rainfall_mm","Flood_Occurred_Clean",
            "Flood_Severity_Clean","Affected_LGAs_Clean","Persons_Displaced_Clean",
            "Casualties_Clean","Economic_Loss_Clean","Data_Source_Clean"]].copy()
clean.columns = ["State","Date","Year","Month","Rainfall_mm","Flood_Occurred",
                  "Flood_Severity","Affected_LGAs","Persons_Displaced",
                  "Casualties","Economic_Loss_NGN","Data_Source"]
clean = clean.sort_values(["State","Date"]).reset_index(drop=True)

clean.to_csv("nigeria_rainfall_flood_planning_CLEAN.csv", index=False)

print("Rows before:", before_rows)
print("Rows after cleaning:", len(clean))
print("Rows dropped (dupes/blank/unparseable date/invalid state):", before_rows - len(clean))
print("\nSample cleaned rows:")
print(clean.head(8).to_string())
