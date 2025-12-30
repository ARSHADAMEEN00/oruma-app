import mongoose, { Schema, Document } from 'mongoose';
import { HomeVisit } from './index';

export interface HomeVisitDocument extends HomeVisit, Document {}

const HomeVisitSchema = new Schema<HomeVisitDocument>(
  {
    patientName: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    visitDate: { type: String, required: true, trim: true },
    notes: { type: String, trim: true },
  },
  { timestamps: true }
);

export const HomeVisitModel =
  mongoose.models.HomeVisit ||
  mongoose.model<HomeVisitDocument>('HomeVisit', HomeVisitSchema);


