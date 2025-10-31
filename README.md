# Smart Fleet Monitoring & Analysis - Hackathon Submission

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
- `Send_Email`: Mengirim notifikasi via email  
- `Send_telegram_message`: Mengirim notifikasi via Telegram  

---

## 4. Data Integration / Ingestion Procedures
- `SP_CARS`  
- `SP_CUSTOMERS`  
- `SP_MAINTENANCES`  
- `SP_MAINTENANCES_INFO`  
- `SP_RENTALS`  
- `SP_VEHICLE_TELEMETRY`
- `SP_ING_RENTALS_VEHICLE`

> Semua prosedur ini mengambil data dari **stage internal** `Transportation_INT_stage` dan mengisi tabel target di schema `Transportation`.

---

## 5. Snowflake Intelligence Integration = Smart Fleet Monitoring & Analysis Agent
### Agent Configuration
- **Semantic Views**: `CUSTOMER_FLEET_ANALYTICS`
- **Cortex Search Services**: `MAINTENANCE_SERVICE`  
- **Custom Tools**: procedure yang tersedia untuk interaksi AI  

### Contoh Pertanyaan Snowflake Intelligence Agent 5W1H :
1. *“Kapan mobil Toyota Avanza perlu servis berikutnya?”*  
2. *“Siapa pelanggan dengan total sewa tertinggi bulan ini?”*  
3. *“Unit mana yang idle lebih dari 5 hari?”*  

> Semua Pertanyaan di-resolve menggunakan **Snowflake Intelligence Agent**, mengakses semantic views, search services, dan custom tools.

---

## 6. How to Run / Development Notes

### 🔹 1️⃣ Clone Repository
Clone proyek dari GitHub ke lokal:

```bash
git clone https://github.com/dai2-metrodata/hackathon_snowflake_2025.git
cd hackathon_snowflake_2025
```

### 🔹 2️⃣ Upload Dataset ke Snowflake Stage

1. Buka Snowsight (Snowflake Web UI)
2. Jalankan perintah SQL berikut untuk membuat internal stage:
```sql
USE DATABASE Hackathon_snowflake;
USE SCHEMA Transportation;

CREATE OR REPLACE STAGE Transportation_INT_stage;
```
3. Upload file CSV ke stage

### 🔹 3️⃣ Jalankan Stored Procedures untuk Ingestion

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

### 🔹 4️⃣ Buat Semantic Views

Buat semantic views untuk digunakan di Snowflake Intelligence Agent-GUI (Cortex Analyst)

### 🔹 5️⃣ Development Procedures untuk Custom Tools:

Daftarkan semua custom tools (procedure):
```sql
-- Notification handlers
CREATE OR REPLACE PROCEDURE Send_Email() 
RETURNS STRING LANGUAGE SQL AS $$ ... $$;

CREATE OR REPLACE PROCEDURE Send_telegram_message() 
RETURNS STRING LANGUAGE SQL AS $$ ... $$;
```

### 🔹 6️⃣ Konfigurasi Snowflake Cortex Intelligence Agent

1. Masuk ke Snowflake Console → AI & ML → Agents
2. Klik Create Agent
3. Tambahkan konfigurasi berikut:
```
Semantic Views:
        - Customer_fleet_analytics
Cortex Search Service:
        - Maintenance_service
Custom Tools:
        - Send_Email, Send_telegram_message
```
4. Klik Save & Deploy
5. Tes pertanyaan berikut di GUI:
```
“Kapan mobil Toyota Avanza perlu servis berikutnya?”

“Mobil mana yang idle lebih dari 5 hari?”

“Siapa pelanggan paling loyal bulan ini?”
```