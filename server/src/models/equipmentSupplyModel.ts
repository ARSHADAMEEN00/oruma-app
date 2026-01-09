import mongoose, { Schema, Document } from 'mongoose';
import { EquipmentSupply } from './index';

export interface EquipmentSupplyDocument extends EquipmentSupply, Document { }

const EquipmentSupplySchema = new Schema<EquipmentSupplyDocument>(
  {
    equipmentId: { type: String, required: true, ref: 'Equipment' },
    equipmentUniqueId: { type: String, required: true, trim: true },
    equipmentName: { type: String, required: true, trim: true },
    patientName: { type: String, trim: true },
    patientPhone: { type: String, trim: true },
    patientAddress: { type: String, trim: true },
    careOf: { type: String, trim: true },
    receiverName: { type: String, trim: true },
    receiverPhone: { type: String, trim: true },
    receiverAddress: { type: String, trim: true },
    receiverPlace: { type: String, trim: true },
    supplyDate: { type: String, required: true },
    returnDate: { type: String },
    actualReturnDate: { type: String },
    status: {
      type: String,
      enum: ['active', 'returned', 'lost'],
      default: 'active'
    },
    notes: { type: String, trim: true },
    returnNote: { type: String, trim: true },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

// Indexes for faster queries
EquipmentSupplySchema.index({ status: 1 });
EquipmentSupplySchema.index({ equipmentId: 1 });
EquipmentSupplySchema.index({ patientName: 1 });

export const EquipmentSupplyModel =
  mongoose.models.EquipmentSupply ||
  mongoose.model<EquipmentSupplyDocument>(
    'EquipmentSupply',
    EquipmentSupplySchema
  );
