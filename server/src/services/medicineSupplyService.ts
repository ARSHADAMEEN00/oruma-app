import { MedicineSupply } from '../models';

let medicineSupplies: MedicineSupply[] = [];
let medicineSupplyIdCounter = 1;

export const medicineSupplyService = {
  create: async (supply: MedicineSupply): Promise<MedicineSupply> => {
    const newSupply: MedicineSupply = {
      ...supply,
      id: `MS${medicineSupplyIdCounter++}`,
      createdAt: new Date(),
    };
    medicineSupplies.push(newSupply);
    return newSupply;
  },

  getAll: async (): Promise<MedicineSupply[]> => {
    return [...medicineSupplies];
  },

  getById: async (id: string): Promise<MedicineSupply | undefined> => {
    return medicineSupplies.find(s => s.id === id);
  },

  update: async (id: string, updates: Partial<MedicineSupply>): Promise<MedicineSupply | null> => {
    const index = medicineSupplies.findIndex(s => s.id === id);
    if (index === -1) return null;
    
    medicineSupplies[index] = { ...medicineSupplies[index], ...updates };
    return medicineSupplies[index];
  },

  delete: async (id: string): Promise<boolean> => {
    const index = medicineSupplies.findIndex(s => s.id === id);
    if (index === -1) return false;
    
    medicineSupplies.splice(index, 1);
    return true;
  },
};

