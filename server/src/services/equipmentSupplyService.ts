import { EquipmentSupply } from '../models';
import { EquipmentSupplyModel } from '../models/equipmentSupplyModel';
import { EquipmentModel } from '../models/equipmentModel';

export const equipmentSupplyService = {
  create: async (supplyData: EquipmentSupply): Promise<EquipmentSupply> => {
    // 1. Validate Equipment
    const equipment = await EquipmentModel.findById(supplyData.equipmentId);
    if (!equipment) {
      throw new Error('Equipment not found');
    }
    if (equipment.status !== 'available') {
      throw new Error(`Equipment ${equipment.uniqueId} is not available (Status: ${equipment.status})`);
    }

    // 2. Create Supply Record
    const newSupply = await EquipmentSupplyModel.create({
      ...supplyData,
      status: 'active',
      equipmentUniqueId: equipment.uniqueId,
      equipmentName: equipment.name,
      supplyDate: new Date().toISOString(),
    });

    // 3. Update Equipment Status
    equipment.status = 'supplied';
    await equipment.save();

    return toEquipmentSupply(newSupply);
  },

  getAll: async (): Promise<EquipmentSupply[]> => {
    const list = await EquipmentSupplyModel.find().sort({ createdAt: -1 }).lean();
    return list.map(toEquipmentSupply);
  },

  getById: async (id: string): Promise<EquipmentSupply | null> => {
    const found = await EquipmentSupplyModel.findById(id).lean();
    return found ? toEquipmentSupply(found) : null;
  },

  // Get active supplies (currently with patients)
  getActive: async (): Promise<EquipmentSupply[]> => {
    const list = await EquipmentSupplyModel.find({ status: 'active' }).sort({ createdAt: -1 }).lean();
    return list.map(toEquipmentSupply);
  },

  update: async (id: string, updates: Partial<EquipmentSupply>): Promise<EquipmentSupply | null> => {
    const currentSupply = await EquipmentSupplyModel.findById(id);
    if (!currentSupply) return null;

    // Check if confirming return
    if (updates.status === 'returned' && currentSupply.status === 'active') {
      const equipment = await EquipmentModel.findById(currentSupply.equipmentId);
      if (equipment) {
        equipment.status = 'available';
        await equipment.save();
      }
      updates.actualReturnDate = new Date().toISOString();
    }

    const updated = await EquipmentSupplyModel.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    }).lean();
    return updated ? toEquipmentSupply(updated) : null;
  },

  delete: async (id: string): Promise<boolean> => {
    const supply = await EquipmentSupplyModel.findById(id);
    if (!supply) return false;

    // If deleting an active supply, make equipment available again
    if (supply.status === 'active') {
      const equipment = await EquipmentModel.findById(supply.equipmentId);
      if (equipment) {
        equipment.status = 'available';
        await equipment.save();
      }
    }

    await EquipmentSupplyModel.findByIdAndDelete(id);
    return true;
  },
};

function toEquipmentSupply(doc: any): EquipmentSupply {
  return {
    id: doc._id.toString(),
    equipmentId: doc.equipmentId,
    equipmentUniqueId: doc.equipmentUniqueId,
    equipmentName: doc.equipmentName,
    patientName: doc.patientName,
    patientPhone: doc.patientPhone,
    patientAddress: doc.patientAddress,
    supplyDate: doc.supplyDate,
    returnDate: doc.returnDate,
    actualReturnDate: doc.actualReturnDate,
    status: doc.status,
    notes: doc.notes,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}
