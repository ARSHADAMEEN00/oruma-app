import { MedicineSupply } from '../models';
import { MedicineSupplyModel } from '../models/medicineSupplyModel';

export const medicineSupplyService = {
  create: async (supply: MedicineSupply): Promise<MedicineSupply> => {
    const created = await MedicineSupplyModel.create(supply);
    return toMedicineSupply(created);
  },

  getAll: async (): Promise<MedicineSupply[]> => {
    const list = await MedicineSupplyModel.find()
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 })
      .lean();
    return list.map(toMedicineSupply);
  },

  getById: async (id: string): Promise<MedicineSupply | null> => {
    const found = await MedicineSupplyModel.findById(id)
      .populate('createdBy', 'name')
      .lean();
    return found ? toMedicineSupply(found) : null;
  },

  update: async (id: string, updates: Partial<MedicineSupply>): Promise<MedicineSupply | null> => {
    const updated = await MedicineSupplyModel.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    })
      .populate('createdBy', 'name')
      .lean();
    return updated ? toMedicineSupply(updated) : null;
  },

  delete: async (id: string): Promise<boolean> => {
    const res = await MedicineSupplyModel.findByIdAndDelete(id);
    return Boolean(res);
  },
};

function toMedicineSupply(doc: any): MedicineSupply {
  return {
    id: doc._id.toString(),
    patientName: doc.patientName,
    medicine: doc.medicine,
    quantity: doc.quantity,
    phone: doc.phone,
    address: doc.address,
    createdAt: doc.createdAt,
    createdBy: doc.createdBy && typeof doc.createdBy === 'object' && 'name' in doc.createdBy
      ? (doc.createdBy as any).name
      : doc.createdBy?.toString(),
  };
}


