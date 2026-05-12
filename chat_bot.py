# =========================================================
# AI HR Analytics Chatbot using Gemini NEW SDK
# Streamlit + SQL Server + Gemini + Selenium
# FULL SINGLE FILE APPLICATION (FIXED)
# =========================================================

import streamlit as st
import pandas as pd
from google import genai
from sqlalchemy import create_engine
import plotly.express as px
import time
import warnings

# Selenium
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

warnings.filterwarnings("ignore")

# =========================================================
# GEMINI CONFIG (NEW SDK)
# =========================================================

GEMINI_API_KEY = "AIzaSyBc2zPsnngMN-NRYt2J2KV3fs6FX7jWM78"

client = genai.Client(
    api_key=GEMINI_API_KEY
)

MODEL_ID = "models/gemini-2.5-flash"

# =========================================================
# SQL SERVER
# =========================================================

server = "."
database = "dw_HR"

engine = create_engine(
    f"mssql+pyodbc://@{server}/{database}"
    "?driver=ODBC+Driver+18+for+SQL+Server"
    "&TrustServerCertificate=yes"
)

# =========================================================
# STREAMLIT UI
# =========================================================

st.set_page_config(
    page_title="HR AI Chatbot",
    page_icon="🤖",
    layout="wide"
)

st.title("🤖 AI HR Business Intelligence Assistant")

st.markdown("""
Ask HR questions:
- Attrition rate
- Salary analysis
- Overtime employees
- Years at company
""")

# =========================================================
# MEMORY
# =========================================================

if "chat_history" not in st.session_state:
    st.session_state.chat_history = []

# =========================================================
# SCHEMA
# =========================================================

SCHEMA = """
Table: fact_HR

Columns:
Attrition, MonthlyIncome, OverTime,
YearsAtCompany, PercentSalaryHike, EmployeeID
"""

# =========================================================
# GEMINI CALL (NEW)
# =========================================================

def ask_gemini(prompt):

    response = client.models.generate_content(
        model=MODEL_ID,
        contents=prompt
    )

    return response.text

# =========================================================
# KPI SIDEBAR
# =========================================================

st.sidebar.title("📊 KPIs")

try:

    df_kpi = pd.read_sql("SELECT * FROM fact_HR", engine)

    st.sidebar.metric("Employees", len(df_kpi))
    st.sidebar.metric("Avg Salary", round(df_kpi["MonthlyIncome"].mean(), 2))

    attrition_rate = len(df_kpi[df_kpi["Attrition"] == "Yes"]) / len(df_kpi) * 100
    st.sidebar.metric("Attrition %", round(attrition_rate, 2))

except:
    st.sidebar.error("DB Error")

# =========================================================
# SQL GENERATOR
# =========================================================

def generate_sql(question):

    prompt = f"""
You are an HR Data Analyst.

Schema:
{SCHEMA}

Rules:
- SQL Server only
- Only fact_HR table
- No DELETE/UPDATE/INSERT
- Return ONLY SQL

Question:
{question}
"""

    sql = ask_gemini(prompt)

    return sql.replace("```sql", "").replace("```", "").strip()

# =========================================================
# VALIDATION
# =========================================================

def validate(sql):

    bad = ["DELETE","DROP","UPDATE","INSERT","ALTER","TRUNCATE"]

    for b in bad:
        if b in sql.upper():
            raise Exception("Unsafe SQL detected")

# =========================================================
# RUN SQL
# =========================================================

def run_sql(sql):

    validate(sql)

    return pd.read_sql(sql, engine)

# =========================================================
# SUMMARY
# =========================================================

def summary(q, df):

    if df.empty:
        return "No data found"

    prompt = f"""
Question: {q}

Data:
{df.head(10).to_string()}

Give HR business insight in simple words.
"""

    return ask_gemini(prompt)

# =========================================================
# CHART
# =========================================================

def chart(df):

    if len(df.columns) < 2:
        return None

    return px.bar(df, x=df.columns[0], y=df.columns[1])

# =========================================================
# SELENIUM SCRAPER
# =========================================================

def scrape_news():

    options = Options()
    options.add_argument("--headless")

    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=options
    )

    driver.get("https://www.shrm.org")
    time.sleep(5)

    data = []

    for h in driver.find_elements(By.TAG_NAME, "h2")[:8]:
        if h.text:
            data.append(h.text)

    driver.quit()

    return data

# =========================================================
# NEWS
# =========================================================

st.subheader("📰 HR News")

if st.button("Load News"):

    news = scrape_news()

    for n in news:
        st.write("✔", n)

# =========================================================
# CHAT INPUT
# =========================================================

q = st.chat_input("Ask HR question...")

if q:

    st.session_state.chat_history.append({
        "role": "user",
        "content": q
    })

    try:

        sql = generate_sql(q)

        st.code(sql, language="sql")

        df = run_sql(sql)

        ans = summary(q, df)

        st.success(ans)

        st.dataframe(df)

        c = chart(df)

        if c:
            st.plotly_chart(c)

        csv = df.to_csv(index=False).encode("utf-8")

        st.download_button(
            "Download CSV",
            csv,
            "hr.csv"
        )

    except Exception as e:
        st.error(str(e))

# =========================================================
# HISTORY
# =========================================================

st.subheader("Chat History")

for h in st.session_state.chat_history:

    st.write(h["role"], ":", h["content"])