import { Patient } from '../models';
import { PatientModel } from '../models/patientModel';

export const patientService = {
  create: async (patient: Patient): Promise<Patient> => {
    const created = await PatientModel.create(patient);
    return toPatient(created);
  },

  getAll: async (): Promise<Patient[]> => {
    const list = await PatientModel.find().sort({ createdAt: -1 }).lean();
    return list.map(toPatient);
  },

  getById: async (id: string): Promise<Patient | null> => {
    const found = await PatientModel.findById(id).lean();
    return found ? toPatient(found) : null;
  },

  update: async (id: string, updates: Partial<Patient>): Promise<Patient | null> => {
    const updated = await PatientModel.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    }).lean();
    return updated ? toPatient(updated) : null;
  },

  delete: async (id: string): Promise<boolean> => {
    const res = await PatientModel.findByIdAndDelete(id);
    return Boolean(res);
  },
};

function toPatient(doc: any): Patient {
  return {
    id: doc._id.toString(),
    name: doc.name,
    relation: doc.relation,
    gender: doc.gender,
    address: doc.address,
    phone: doc.phone,
    age: doc.age,
    place: doc.place,
    village: doc.village,
    disease: doc.disease,
    plan: doc.plan,
    createdAt: doc.createdAt,
  };
}

