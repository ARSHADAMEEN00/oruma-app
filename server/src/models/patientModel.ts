import mongoose, { Schema, Document } from 'mongoose';
import { Patient } from './index';

export interface PatientDocument extends Patient, Document { }

const PatientSchema = new Schema<PatientDocument>(
  {
    name: { type: String, required: true, trim: true },
    relation: { type: String, required: true, trim: true },
    gender: { type: String, enum: ['Male', 'Female', 'Other'], required: true },
    address: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    age: { type: Number, required: true, min: 0 },
    place: { type: String, required: true, trim: true },
    village: { type: String, required: true, trim: true },
    disease: { type: String, required: true, trim: true },
    plan: { type: String, required: true, trim: true },
    registerId: { type: String, unique: true, sparse: true },
    isDead: { type: Boolean, default: false },
    dateOfDeath: { type: Date },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

export const PatientModel =
  mongoose.models.Patient ||
  mongoose.model<PatientDocument>('Patient', PatientSchema);


