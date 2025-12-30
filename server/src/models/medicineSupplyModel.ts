import mongoose, { Schema, Document } from 'mongoose';
import { MedicineSupply } from './index';

export interface MedicineSupplyDocument extends MedicineSupply, Document {}

const MedicineSupplySchema = new Schema<MedicineSupplyDocument>(
  {
    patientName: { type: String, required: true, trim: true },
    medicine: { type: String, required: true, trim: true },
    quantity: { type: Number, required: true, min: 0 },
    phone: { type: String, required: true, trim: true },
    address: { type: String, trim: true },
  },
  { timestamps: true }
);

export const MedicineSupplyModel =
  mongoose.models.MedicineSupply ||
  mongoose.model<MedicineSupplyDocument>(
    'MedicineSupply',
    MedicineSupplySchema
  );


