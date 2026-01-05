import { Patient } from '../models';
import { PatientModel } from '../models/patientModel';

export const patientService = {
  create: async (patient: Patient): Promise<Patient> => {
    const currentYear = new Date().getFullYear().toString().slice(-2);

    // Find the latest patient in the current year using aggregation for numeric prefix sorting
    const lastPatients = await PatientModel.aggregate([
      {
        $match: {
          registerId: { $regex: new RegExp(`/${currentYear}$`) }
        }
      },
      {
        $addFields: {
          idParts: { $split: ["$registerId", "/"] }
        }
      },
      {
        $addFields: {
          idPrefix: { $toInt: { $arrayElemAt: ["$idParts", 0] } }
        }
      },
      {
        $sort: { idPrefix: -1 }
      },
      {
        $limit: 1
      }
    ]);

    let nextNumber = 1;
    if (lastPatients.length > 0 && lastPatients[0].registerId) {
      const currentId = lastPatients[0].registerId.split('/')[0];
      nextNumber = parseInt(currentId, 10) + 1;
    }

    patient.registerId = `${nextNumber.toString().padStart(2, '0')}/${currentYear}`;

    // Handle registrationDate - use provided date or default to today
    const patientData: any = { ...patient };
    if (patient.registrationDate) {
      patientData.registrationDate = new Date(patient.registrationDate);
    } else {
      patientData.registrationDate = new Date(); // Default to today
    }

    const created = await PatientModel.create(patientData);
    return toPatient(created);
  },

  getAll: async (filter: any = {}): Promise<Patient[]> => {
    const query: any = {};
    if (filter.isDead !== undefined) {
      query.isDead = filter.isDead === 'true' || filter.isDead === true;
    }
    const list = await PatientModel.find(query).sort({ createdAt: -1 }).lean();
    return list.map(toPatient);
  },

  getById: async (id: string): Promise<Patient | null> => {
    const found = await PatientModel.findById(id).lean();
    return found ? toPatient(found) : null;
  },

  update: async (id: string, updates: Partial<Patient>): Promise<Patient | null> => {
    // Handle registrationDate if provided in updates
    const updateData: any = { ...updates };
    if (updates.registrationDate) {
      updateData.registrationDate = new Date(updates.registrationDate);
    }

    const updated = await PatientModel.findByIdAndUpdate(id, updateData, {
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
    phone2: doc.phone2,
    age: doc.age,
    place: doc.place,
    village: doc.village,
    disease: doc.disease,
    plan: doc.plan,
    registerId: doc.registerId,
    registrationDate: doc.registrationDate ? doc.registrationDate.toISOString() : undefined,
    isDead: doc.isDead,
    dateOfDeath: doc.dateOfDeath ? doc.dateOfDeath.toISOString() : undefined,
    createdAt: doc.createdAt,
    createdBy: doc.createdBy ? doc.createdBy.toString() : undefined,
  };
}

