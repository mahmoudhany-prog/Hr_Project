HR Attrition & Retention Intelligence System 🤖📊
📋 Project Overview
This project is an end-to-end HR Analytics solution designed to uncover the root causes of employee turnover (attrition). It combines the power of SQL Server for data management, Power BI for advanced visualization, and Google Gemini AI for generating strategic retention plans.
The goal is to move from descriptive analytics (what happened) to prescriptive analytics (what should we do).
🚀 Key Features
1.	Executive Dashboard: A high-level overview of the financial impact ($497K+ annual loss) and key KPIs.
2.	AI Strategic Assistant: A Python-based chatbot integrated with Gemini AI to provide real-time HR advice and job market analysis.
3.	Burnout & Wellbeing Analysis: Detailed tracking of how Overtime (OT) correlates with attrition and employee satisfaction.
4.	"Year 0" Retention Focus: Specialized analysis for new hires to mitigate the high 53.52% turnover rate in the first year.
5.	Salary Fairness Auditor: Identifying pay gaps across generations (Gen Z, Millennials, Gen X) and departments.
🛠️ Tech Stack
•	Database: SQL Server (Complex Joins, CTEs, and Aggregations).
•	Visualization: Power BI (DAX, Interactive Slicers, Star Schema).
•	Programming: Python (Streamlit for UI, PyODBC for SQL connection).
•	AI Model: Google Gemini 2.5 Flash (Strategic content generation).
•	Web Integration: HTML/Tailwind CSS for AI-powered infographics.
📊 Dashboard Insights (Visual Analysis)
Based on the developed Power BI dashboards (referenced in images 1-5):
1. Executive Summary
•	Attrition Rate: $30.58\%$.
•	Total Financial Loss: Approximately $\$497,281$.
•	Critical Departments: Sales and Human Resources show the highest risk.
2. Attrition Drivers
•	Distance Factor: Employees living $15km+$ away (Far) are significantly more likely to resign.
•	Manager Impact: Attrition peaks in the first two years of working with a new manager, suggesting a need for better leadership onboarding.
3. Financial & Demographic Analysis
•	The Generation Gap: Gen Z employees represent the highest attrition risk despite having the lowest salaries, while Gen X+ holds the highest stability.
•	Pay Equity: Significant salary differences were identified in "Laboratory Technician" and "Sales Executive" roles compared to department averages.
4. Wellbeing & Overtime
•	The Burnout Trigger: Working Overtime (OT) leads to an 87.5% attrition rate in specific roles like Sales Representatives.
💻 Installation & Setup
Prerequisites
•	SQL Server with the mostaql database attached.
•	Python 3.10+
•	Google Gemini API Key.
Steps
1.	Clone the Repository:
2.	git clone https://github.com/yourusername/hr-analytics-ai.git
3.	Install Dependencies:
4.	pip install streamlit pandas pyodbc google-genai
5.	Database Configuration: Ensure your SQL Server connection string in hr_chatbot.py matches your local environment.
6.	Run the Chatbot:
7.	streamlit run hr_chatbot.py
📈 Strategic Recommendations
•	Implement Hybrid Work: Specifically for employees in the "Far" distance category to reduce commute burnout.
•	OT Ceiling: Set a cap on overtime for Junior roles to prevent early-stage resignations.
•	Junior Mentorship: Targeted retention programs for Year 0 employees to lower the $53.52\%$ turnover rate.

