import { Patient } from '../models';

// In-memory storage (replace with database in production)
let patients: Patient[] = [];
let patientIdCounter = 1;

export const patientService = {
  create: async (patient: Patient): Promise<Patient> => {
    const newPatient: Patient = {
      ...patient,
      id: `PAT${patientIdCounter++}`,
      createdAt: new Date(),
    };
    patients.push(newPatient);
    return newPatient;
  },

  getAll: async (): Promise<Patient[]> => {
    return [...patients];
  },

  getById: async (id: string): Promise<Patient | undefined> => {
    return patients.find(p => p.id === id);
  },

  update: async (id: string, updates: Partial<Patient>): Promise<Patient | null> => {
    const index = patients.findIndex(p => p.id === id);
    if (index === -1) return null;
    
    patients[index] = { ...patients[index], ...updates };
    return patients[index];
  },

  delete: async (id: string): Promise<boolean> => {
    const index = patients.findIndex(p => p.id === id);
    if (index === -1) return false;
    
    patients.splice(index, 1);
    return true;
  },
};

