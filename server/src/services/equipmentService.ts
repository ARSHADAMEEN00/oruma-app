import { Equipment } from '../models';
import { EquipmentModel } from '../models/equipmentModel';

// Helper to generate unique ID like "WH-001", "WH-002"
async function generateUniqueId(baseName: string): Promise<string> {
  // Create prefix from first 2 letters of name (uppercase)
  const prefix = baseName
    .replace(/[^a-zA-Z]/g, '')
    .substring(0, 2)
    .toUpperCase() || 'EQ';

  // Find the highest existing number for this prefix
  const lastEquipment = await EquipmentModel.findOne({
    uniqueId: { $regex: `^${prefix}-\\d+$` }
  })
    .sort({ uniqueId: -1 })
    .lean();

  let nextNumber = 1;
  if (lastEquipment && lastEquipment.uniqueId) {
    const match = lastEquipment.uniqueId.match(/(\d+)$/);
    if (match) {
      nextNumber = parseInt(match[1], 10) + 1;
    }
  }

  return `${prefix}-${nextNumber.toString().padStart(3, '0')}`;
}

// Helper to generate multiple unique IDs
async function generateMultipleUniqueIds(baseName: string, count: number): Promise<string[]> {
  const prefix = baseName
    .replace(/[^a-zA-Z]/g, '')
    .substring(0, 2)
    .toUpperCase() || 'EQ';

  // Find the highest existing number for this prefix
  const lastEquipment = await EquipmentModel.findOne({
    uniqueId: { $regex: `^${prefix}-\\d+$` }
  })
    .sort({ uniqueId: -1 })
    .lean();

  let nextNumber = 1;
  if (lastEquipment && lastEquipment.uniqueId) {
    const match = lastEquipment.uniqueId.match(/(\d+)$/);
    if (match) {
      nextNumber = parseInt(match[1], 10) + 1;
    }
  }

  const uniqueIds: string[] = [];
  for (let i = 0; i < count; i++) {
    uniqueIds.push(`${prefix}-${(nextNumber + i).toString().padStart(3, '0')}`);
  }
  return uniqueIds;
}

export const equipmentService = {
  // Create equipment - if quantity > 1, creates multiple individual records
  create: async (eq: Equipment): Promise<Equipment[]> => {
    const quantity = eq.quantity || 1;

    // Generate unique IDs for all items
    const uniqueIds = await generateMultipleUniqueIds(eq.name, quantity);

    // Create individual equipment records
    const equipmentDocs = uniqueIds.map((uniqueId) => ({
      uniqueId,
      serialNo: eq.serialNo,
      name: eq.name,
      quantity: 1,  // Each record represents 1 item
      purchasedFrom: eq.purchasedFrom,
      place: eq.place,
      phone: eq.phone,
      status: 'available',
      createdBy: eq.createdBy,
    }));

    const created = await EquipmentModel.insertMany(equipmentDocs);
    return created.map(toEquipment);
  },

  // Create a single equipment with specific uniqueId
  createSingle: async (eq: Equipment): Promise<Equipment> => {
    const uniqueId = eq.uniqueId || await generateUniqueId(eq.name);
    const created = await EquipmentModel.create({
      ...eq,
      uniqueId,
      quantity: 1,
      status: eq.status || 'available',
    });
    return toEquipment(created);
  },

  getAll: async (): Promise<Equipment[]> => {
    const list = await EquipmentModel.find().sort({ createdAt: -1 }).lean();
    return list.map(toEquipment);
  },

  // Get equipment filtered by status
  getByStatus: async (status: string): Promise<Equipment[]> => {
    const list = await EquipmentModel.find({ status }).sort({ createdAt: -1 }).lean();
    return list.map(toEquipment);
  },

  // Get available equipment count by name
  getAvailableCount: async (): Promise<Record<string, number>> => {
    const result = await EquipmentModel.aggregate([
      { $match: { status: 'available' } },
      { $group: { _id: '$name', count: { $sum: 1 } } }
    ]);
    return result.reduce((acc: Record<string, number>, item: any) => {
      acc[item._id] = item.count;
      return acc;
    }, {} as Record<string, number>);
  },

  getById: async (id: string): Promise<Equipment | null> => {
    const found = await EquipmentModel.findById(id).lean();
    return found ? toEquipment(found) : null;
  },

  // Get by unique ID
  getByUniqueId: async (uniqueId: string): Promise<Equipment | null> => {
    const found = await EquipmentModel.findOne({ uniqueId }).lean();
    return found ? toEquipment(found) : null;
  },

  update: async (id: string, updates: Partial<Equipment>): Promise<Equipment | null> => {
    const updated = await EquipmentModel.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    }).lean();
    return updated ? toEquipment(updated) : null;
  },

  // Update status
  updateStatus: async (id: string, status: 'available' | 'supplied' | 'maintenance'): Promise<Equipment | null> => {
    const updated = await EquipmentModel.findByIdAndUpdate(
      id,
      { status },
      { new: true }
    ).lean();
    return updated ? toEquipment(updated) : null;
  },

  delete: async (id: string): Promise<boolean> => {
    const res = await EquipmentModel.findByIdAndDelete(id);
    return Boolean(res);
  },
};

function toEquipment(doc: any): Equipment {
  return {
    id: doc._id?.toString(),
    uniqueId: doc.uniqueId,
    serialNo: doc.serialNo,
    name: doc.name,
    quantity: doc.quantity,
    purchasedFrom: doc.purchasedFrom,
    place: doc.place,
    phone: doc.phone,
    status: doc.status,
    createdAt: doc.createdAt,
    createdBy: doc.createdBy ? doc.createdBy.toString() : undefined,
  };
}
