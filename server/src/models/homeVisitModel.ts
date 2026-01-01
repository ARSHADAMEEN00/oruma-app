import mongoose, { Schema, Document } from 'mongoose';
import { HomeVisit } from './index';

export interface HomeVisitDocument extends HomeVisit, Document { }

const HomeVisitSchema = new Schema<HomeVisitDocument>(
  {
    patientName: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    visitDate: { type: String, required: true, trim: true },
    visitMode: {
      type: String,
      enum: ['monthly', 'emergency', 'new'],
      default: 'new',
      required: true,
    },
    notes: { type: String, trim: true },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

export const HomeVisitModel =
  mongoose.models.HomeVisit ||
  mongoose.model<HomeVisitDocument>('HomeVisit', HomeVisitSchema);


