import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDb } from './db';

// Import routes
import authRoutes from './routes/authRoutes';
import patientsRouter from './routes/patients';
import homeVisitsRouter from './routes/homeVisits';
import equipmentRouter from './routes/equipment';
import equipmentSuppliesRouter from './routes/equipmentSupplies';
import medicineSuppliesRouter from './routes/medicineSupplies';
import { protect } from './middleware/auth';

// Load environment variables
dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || '';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'OK', message: 'Oruma API Server is running' });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/patients', protect, patientsRouter);
app.use('/api/home-visits', protect, homeVisitsRouter);
app.use('/api/equipment', protect, equipmentRouter);
app.use('/api/equipment-supplies', protect, equipmentSuppliesRouter);
app.use('/api/medicine-supplies', protect, medicineSuppliesRouter);

// Root endpoint
app.get('/', (req: Request, res: Response) => {
  res.json({
    message: 'Welcome to Oruma API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      patients: '/api/patients',
      homeVisits: '/api/home-visits',
      equipment: '/api/equipment',
      equipmentSupplies: '/api/equipment-supplies',
      medicineSupplies: '/api/medicine-supplies',
    },
  });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err: Error, req: Request, res: Response, next: Function) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server after DB connect
connectDb(MONGO_URI)
  .then(() => {
    app.listen(PORT, () => {
      console.log(`🚀 Oruma API Server is running on http://localhost:${PORT}`);
      console.log(`📋 Health check: http://localhost:${PORT}/health`);
    });
  })
  .catch((err) => {
    console.error('Failed to connect to MongoDB', err);
    process.exit(1);
  });

