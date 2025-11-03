# Smart Fleet Monitoring & Analysis Assistance - Hackathon Submission

## 👥 Team

**Team Name:** DAI 2

**Team Members:**
- **Rinno Julio Bagus**
- **Andang Chrisnandi** 
- **Fauzan Al Agung** 

## 1. Project Overview
**Smart Fleet Monitoring & Analysis** adalah solusi end-to-end untuk manajemen armada rental mobil berbasis **Snowflake Intelligence (Agent)** dan **custom tools**, yang memungkinkan:

- **Predictive Maintenance**: Memprediksi kapan kendaraan perlu perawatan.  
- **Customer & Rental Insight**: Analisis perilaku pelanggan dan tren penyewaan.  
- **Fleet Optimization**: Mengoptimalkan utilisasi armada berdasarkan telemetri.  
- **Interaktif AI Agent**: Snowflake Intelligence Agent menjawab pertanyaan natural language dari pengguna.

**Database**: `HACKATHON_SNOWFLAKE`  
**Schema**: `TRANSPORTATION`  
**Stage**: `TRANSPORTATION_INT_STAGE` (internal stage untuk CSV sumber)

---

## 2. Tables & Views
### Tables
- `CARS`  
- `CUSTOMERS`  
- `MAINTENANCES`  
- `MAINTENANCES_INFO` (hasil join `MAINTENANCES` + `CARS`)  
- `RENTALS`  
- `VEHICLE_TELEMETRY`

### Semantic Views (Cortex GUI)
- `CUSTOMER_FLEET_ANALYTICS`  

---

## 3. Custom Tools
### Procedures
- `SEND_EMAIL`: Mengirim notifikasi via email  
- `SEND_TELEGRAM_MESSAGE`: Mengirim notifikasi via Telegram  

---

## 4. Data Integration / Ingestion Procedures
- `SP_CARS` → **TASK_CARS**
- `SP_CUSTOMERS` → **TASK_CUSTOMER**
- `SP_MAINTENANCES` → **TASK_MAINTENANCES**  
- `SP_MAINTENANCES_INFO` → **TASK_MAINTENANCES_INFO**     
- `SP_RENTALS` → **TASK_RENTALS**  
- `SP_VEHICLE_TELEMETRY` → **TASK_VEHICLE_TELEMETRY**
- `SP_ING_RENTALS_VEHICLE` → **TASK_VEHICLE_TELEMETRY** && **TASK_RENTALS** 

> Semua prosedur ini mengambil data dari **stage internal** `Transportation_INT_stage` dan mengisi tabel target di schema `Transportation`.

---
## 5. Data Governance 
### Column Level Security (Data Masking)
Table : Customers
Column : Phone, Email, Driver License Number

## 6. Snowflake Intelligence Integration = Smart Fleet Monitoring & Analysis Agent
### Agent Configuration
- **Semantic Views**: `CUSTOMER_FLEET_ANALYTICS`
- **Cortex Search Services**: `MAINTENANCE_SERVICE`  
- **Custom Tools**: `SEND_EMAIL` & `SEND_TELEGRAM_MESSAGE`

### Contoh Pertanyaan Snowflake Intelligence Agent 5W1H :
1. *“Who -> Customer yang paling sering rental mobil?”*
2. *“What -> Kendaraan mana yg sering disewa Customer tersebut tapi belum available?”*
3. *“When-> Kapan kendaraan tersebut harus dikembalikan ke rental?”*
4. *“Where -> Dimana kendaraan tersebut saat ini?”*
5. *“Send Telegram -> Mengingatkan customer untuk mengembalikan mobil segera”*
6. *“Why -> Kenapa kendaraan tersebut rusak?”*
7. *“How -> Bagaimana cara agar masalah kerusakan kendaraan seperti ini tidak terulang?”*

> Semua Pertanyaan di-resolve menggunakan **Snowflake Intelligence Agent**, mengakses semantic views, search services, dan custom tools.

---

## 7. How to Run / Development Notes

### 🔹 1️⃣A Clone Repository
Clone proyek dari GitHub ke lokal:

```bash
git clone https://github.com/dai2-metrodata/hackathon_snowflake_2025.git
cd hackathon_snowflake_2025
```

### 🔹 1️⃣B Create Workspace Snowflake dari Git
1. Masuk ke Snowflake Console → Projects → Workspaces
2. Create Workspace → From Git repository
3. Pada kolom Repository URL masukkan link URL berikut :
```
    https://github.com/dai2-metrodata/hackathon_snowflake_2025.git
```
4. Pilih API Integration untuk yang sudah dibuat, Jika belum buat dengan menjalankan query berikut :
```
    
    CREATE OR REPLACE API INTEGRATION my_git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/dai2-metrodata/')
    API_USER_AUTHENTICATION = (
    TYPE = snowflake_github_app
    )
    ENABLED = TRUE;

```
5. klik Create

### 🔹 2️⃣ setup.sql
*“jalankan seluruh query dependency yang terdapat pada setup.sql”*

### 🔹 3️⃣ Upload Dataset ke Snowflake Stage

1. Buka Snowsight (Snowflake Web UI)
2. Upload file DATA CSV ke stage

### 🔹 4️⃣A  Buat Stored Procedure dan Task untuk Ingestion Data 

- `run script SP_CARS.sql`
- `run script SP_CUSTOMERS.sql`
- `run script SP_MAINTENANCES.sql`
- `run script SP_MAINTENANCES_INFO.sql`
- `run script SP_RENTALS.sql`
- `run script SP_VEHICLE_TELEMETRY.sql`
- `run script SP_ING_RENTALS_VEHICLE.sql`
- `run script TASK.sql`


### 🔹 4️⃣B  Jalankan Stored Procedures untuk Ingestion

Eksekusi semua stored procedure untuk memuat data dari stage ke tabel utama :
``` sql
CALL SP_CARS();
CALL SP_CUSTOMERS();
CALL SP_MAINTENANCES();
CALL SP_MAINTENANCES_INFO();
CALL SP_RENTALS(CURRENT_DATE());
CALL SP_VEHICLE_TELEMETRY(CURRENT_DATE());
```
Atau scheduled by task_graph, Hasil: Semua data berhasil dimasukkan ke tabel-tabel di schema Transportation.

### 🔹 5️⃣A  Buat Semantic Views untuk Cortex Analyst:

Buat semantic views untuk digunakan di Snowflake Intelligence Agent-GUI (Cortex Analyst):
1. Masuk ke Snowflake Console → AI & ML → Cortex Analyst
2. Klik Create new → Upload your YAML file
3. Upload file yaml:
```
    CUSTOMER_FLEET_ANALYTICS.yaml
```
4. Klik Save & Deploy

### 🔹 5️⃣B  Buat Cortex Search Service untuk Cortex Search:

```sql

    CREATE OR REPLACE CORTEX SEARCH SERVICE maintenance_service
    ON listing_text
    ATTRIBUTES maintenance_type
    WAREHOUSE = compute_small
    TARGET_LAG = '1 hour'
    AS
        SELECT
            maintenance_id,
            car_id,
            maintenance_type,
            maintenance_date,
            cost, 
            next_maintenance_date,
            odometer_at_maintenance,
            maintenance_status,
            workshop_location,
            transmission,
            brand,
            model,
            year,
            fuel_type,
            ('License Plate\n\n' || license_plate || '\n\n\brand\n\n' || brand || '\n\n\model\n\n' || model 
            || '\n\n\year\n\n' || year || '\n\n\fuel_type\n\n' || fuel_type || '\n\transmission\n\n' || transmission || '\n\nDescription\n\n' || description ||  '\n\nMaintenance Status\n\n' || maintenance_status) as listing_text
        FROM MAINTENANCES_INFO;

```

### 🔹 5️⃣C Buat Stored Procedures untuk Custom Tools:

Daftarkan semua custom tools (procedure) -> sudah dicreate di setup.sql
```sql
-- Notification handlers
CREATE OR REPLACE PROCEDURE SEND_EMAIL() 
RETURNS STRING LANGUAGE SQL AS $$ ... $$;

CREATE OR REPLACE PROCEDURE SEND_TELEGRAM_MESSAGE() 
RETURNS STRING LANGUAGE SQL AS $$ ... $$;
```

### 🔹 6️⃣ Konfigurasi Snowflake Intelligence Agent

1. Masuk ke Snowflake Console → AI & ML → Agents
2. Klik Create Agent
3. ✅ Create this agent for Snowflake Intelligence
4. Agent object name : SMARTFLEETMONITORINGAGENT
5. Display name : Smart Fleet Monitoring & Analysis Agent
6. Klik Create Agent
7. Pilih Agent yang sudah dibuat
8. Klik edit
9. Pada tab About tambahkan 
```
Deskripsi : 'Agent ini siap membantu anda menganalisa dan monitoring fleet anda'

Example quetions :
“Customer yang paling sering rental mobil?”
“Kendaraan mana yg sering disewa Customer tersebut tapi belum available?”
“Kapan kendaraan tersebut harus dikembalikan ke rental?”
“Dimana kendaraan tersebut saat ini?”
“Kenapa kendaraan tersebut rusak?”
“Bagaimana cara agar masalah kerusakan kendaraan seperti ini tidak terulang?”

```
10. Pada Tab Tools Tambahkan konfigurasi berikut:

```
- Cortex Analyst → Semantic Views → Customer_fleet_analytics'
  Name : FleetAnalystTools
  Description : Generate with Cortex
  
- Cortex Search Services → MAINTENANCE_SERVICE
  ID column : MAINTENANCE_ID
  Name : MaintenanceTools
  Description : Tools ini membantu anda untuk melihat riwayat dan jadwal detail maintenance kendaraan dari table Maintenances
  
- Custom Tools → SEND_EMAIL, SEND_TELEGRAM
  Resource type : procedure
  Name : SendEmailTools
  Description : Generate with Cortex
  Desc Parameter body : Use HTML-Syntax for this. If the content you get is in markdown, translate it to HTML. If body is not provided, summarize the last question and use that as content for the email.
  Desc Parameter subject : If subject is not provided, use "Snowflake Intelligence".

  Resource type : procedure
  Name : SendTelegramTools
  Description : Tools untuk mengirim pesan lewat telegram. Kirim kan retrun value berupa url/link dan informasikan kepada pengguna untuk membuka url/link tersebut secara manual di browser.
  Desc Parameter body : Use HTML-Syntax for this. If the content you get is in markdown, translate it to HTML. If body is not provided, summarize the last question and use that as content for the email.
  Desc Parameter subject : If subject is not provided, use "Snowflake Intelligence".''
```
11. Pada Tab Orchestration Tambahkan konfigurasi berikut:
Orhestration Instructions : Gunakan Maintenance Tools terlebih dahulu jika berhubungan dengan data riwayat maintenance untuk mencari penyebab kerusakan.

12. Klik Save & Deploy

13. Tes pertanyaan berikut di GUI:
```
“Kapan mobil Toyota Avanza perlu servis berikutnya?”
“Mobil mana yang idle lebih dari 5 hari?”
“Siapa pelanggan paling loyal bulan ini?”
```
### 🔹 6️⃣ Konfigurasi User dan Role
use role accountadmin;
    
    CREATE USER beni
    PASSWORD = 'SecurePassword123!'
    DEFAULT_ROLE = 'ADMIN_ROLE'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH';

    grant role ADMIN_ROLE to user beni;
    grant usage on database hackathon_snowflake to role ADMIN_ROLE;
    grant usage on schema TRANSPORTATION to role ADMIN_ROLE;
    GRANT SELECT ON ALL TABLES IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT USAGE ON ALL CORTEX SEARCH SERVICES IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT ALL ON ALL SEMANTIC VIEWS IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT USAGE ON ALL PROCEDURES IN schema TRANSPORTATION TO ROLE ADMIN_ROLE;
    GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ADMIN_ROLE;
    
    grant usage on database SNOWFLAKE_INTELLIGENCE to role ADMIN_ROLE;
    grant usage on schema SNOWFLAKE_INTELLIGENCE.AGENTS to role ADMIN_ROLE;
    GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.SMARTFLEETMONITORINGAGENT to ROLE ADMIN_ROLE;

    CREATE USER siska
    PASSWORD = 'SecurePassword123!'
    DEFAULT_ROLE = 'ANALYST_ROLE'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH';

    grant role ANALYST_ROLE to user siska;
    grant usage on database hackathon_snowflake to role ANALYST_ROLE;
    grant usage on schema TRANSPORTATION to role ANALYST_ROLE;
    GRANT SELECT ON ALL TABLES IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT USAGE ON ALL CORTEX SEARCH SERVICES IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT ALL ON ALL SEMANTIC VIEWS IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT USAGE ON ALL PROCEDURES IN schema TRANSPORTATION TO ROLE ANALYST_ROLE;
    GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;
    
    grant usage on database SNOWFLAKE_INTELLIGENCE to role ANALYST_ROLE;
    grant usage on schema SNOWFLAKE_INTELLIGENCE.AGENTS to role ANALYST_ROLE;
    GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.SMARTFLEETMONITORINGAGENT to ROLE ANALYST_ROLE;

### 🔹 7️⃣ Snowflake Intelligence

1. Masuk ke Snowflake Console → AI & ML → Snowflake Intelligence
2. Login dengan akun snowflake kamu
3. Pilih agent yang sudah dibuat : Smart Fleet Monitoring & Analysis Agent
4. Snowflake Intelligence siap untuk digunakan 



### Whoop it up !!!