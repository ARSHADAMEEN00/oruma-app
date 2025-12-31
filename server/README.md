# Oruma Backend API

A simple Node.js TypeScript backend API server for the Oruma healthcare application.

## Features

- RESTful API endpoints for:
  - Patient Registration
  - Home Visits
  - Equipment Registration
  - Equipment Supply
  - Medicine Supply
- TypeScript for type safety
- Express.js for routing
- CORS enabled for Flutter app integration
- MongoDB (via Mongoose) for persistent storage

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn

## Installation

1. Navigate to the server directory:
```bash
cd server
```

2. Install dependencies:
```bash
npm install
```

## Running the Server

### Development Mode (with auto-reload):
```bash
npm run dev
```

### Production Mode:
```bash
npm run build
npm start
```

The server will start on `http://localhost:3000` by default.

## Environment Variables

Create a `.env` file in the server directory:
```
PORT=3000
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/oruma
```

## API Endpoints

### Health Check
- `GET /health` - Check if server is running

### Patients
- `GET /api/patients` - Get all patients
- `GET /api/patients/:id` - Get patient by ID
- `POST /api/patients` - Create new patient
- `PUT /api/patients/:id` - Update patient
- `DELETE /api/patients/:id` - Delete patient

### Home Visits
- `GET /api/home-visits` - Get all home visits
- `GET /api/home-visits/:id` - Get home visit by ID
- `POST /api/home-visits` - Create new home visit
- `PUT /api/home-visits/:id` - Update home visit
- `DELETE /api/home-visits/:id` - Delete home visit

### Equipment
- `GET /api/equipment` - Get all equipment
- `GET /api/equipment/:id` - Get equipment by ID
- `POST /api/equipment` - Create new equipment
- `PUT /api/equipment/:id` - Update equipment
- `DELETE /api/equipment/:id` - Delete equipment

### Equipment Supplies
- `GET /api/equipment-supplies` - Get all equipment supplies
- `GET /api/equipment-supplies/:id` - Get equipment supply by ID
- `POST /api/equipment-supplies` - Create new equipment supply
- `PUT /api/equipment-supplies/:id` - Update equipment supply
- `DELETE /api/equipment-supplies/:id` - Delete equipment supply

### Medicine Supplies
- `GET /api/medicine-supplies` - Get all medicine supplies
- `GET /api/medicine-supplies/:id` - Get medicine supply by ID
- `POST /api/medicine-supplies` - Create new medicine supply
- `PUT /api/medicine-supplies/:id` - Update medicine supply
- `DELETE /api/medicine-supplies/:id` - Delete medicine supply

## Example Request Bodies

### Create Patient
```json
{
  "name": "John Doe",
  "relation": "Self",
  "gender": "Male",
  "address": "123 Main St",
  "age": 45,
  "place": "Kodur",
  "village": "Kodur",
  "disease": "CA",
  "plan": "1/4"
}
```

### Create Home Visit
```json
{
  "patientName": "John Doe",
  "address": "123 Main St, Kodur",
  "visitDate": "2024-01-15",
  "notes": "Follow-up visit"
}
```

### Create Equipment
```json
{
  "serialNo": "WC01",
  "name": "Wheelchair",
  "quantity": 1,
  "purchasedFrom": "Medical Store",
  "place": "Kodur",
  "phone": "1234567890"
}
```

### Create Equipment Supply
```json
{
  "patientName": "John Doe",
  "equipment": "Wheelchair",
  "quantity": 1,
  "phone": "1234567890",
  "address": "123 Main St"
}
```

### Create Medicine Supply
```json
{
  "patientName": "John Doe",
  "medicine": "Paracetamol",
  "quantity": 10,
  "phone": "1234567890",
  "address": "123 Main St"
}
```

## Project Structure

```
server/
├── src/
│   ├── models/
│   │   └── index.ts          # TypeScript interfaces
│   ├── routes/
│   │   ├── patients.ts       # Patient routes
│   │   ├── homeVisits.ts     # Home visit routes
│   │   ├── equipment.ts      # Equipment routes
│   │   ├── equipmentSupplies.ts
│   │   └── medicineSupplies.ts
│   ├── services/
│   │   ├── patientService.ts
│   │   ├── homeVisitService.ts
│   │   ├── equipmentService.ts
│   │   ├── equipmentSupplyService.ts
│   │   └── medicineSupplyService.ts
│   └── server.ts             # Main server file
├── dist/                     # Compiled JavaScript (generated)
├── package.json
├── tsconfig.json
└── README.md
```

## Notes

- All endpoints return JSON responses.
- Error responses follow the format: `{ error: "Error message" }`.



  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "watch": "tsc --watch"
  },