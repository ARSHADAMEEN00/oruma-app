import mongoose, { Schema, Document } from 'mongoose';
import { Equipment } from './index';

export interface EquipmentDocument extends Equipment, Document { }

const EquipmentSchema = new Schema<EquipmentDocument>(
  {
    uniqueId: { type: String, required: true, unique: true, trim: true },
    serialNo: { type: String, required: true, trim: true },
    name: { type: String, required: true, trim: true },
    quantity: { type: Number, required: true, min: 1, default: 1 },
    purchasedFrom: { type: String, required: true, trim: true },
    place: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ['available', 'supplied', 'maintenance'],
      default: 'available'
    },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

// Index for faster queries
EquipmentSchema.index({ status: 1 });
EquipmentSchema.index({ name: 1 });

export const EquipmentModel =
  mongoose.models.Equipment ||
  mongoose.model<EquipmentDocument>('Equipment', EquipmentSchema);
