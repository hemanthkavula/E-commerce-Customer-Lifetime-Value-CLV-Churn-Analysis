import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

USER = "root"
PASSWORD = quote_plus("Mysql@2026")   # <-- encode special chars
HOST = "localhost"
PORT = 3306
DB = "retail_clv"

engine = create_engine(
    f"mysql+mysqlconnector://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB}"
)

def read_sql(q: str) -> pd.DataFrame:
    return pd.read_sql(q, engine)

def write_df(df: pd.DataFrame, table: str, if_exists="replace"):
    df.to_sql(table, engine, if_exists=if_exists, index=False)
