import { HomeVisit } from '../models';
import { HomeVisitModel } from '../models/homeVisitModel';

export const homeVisitService = {
  create: async (visit: HomeVisit): Promise<HomeVisit> => {
    const created = await HomeVisitModel.create(visit);
    return toHomeVisit(created);
  },

  getAll: async (): Promise<HomeVisit[]> => {
    const list = await HomeVisitModel.find()
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 })
      .lean();
    return list.map(toHomeVisit);
  },

  getById: async (id: string): Promise<HomeVisit | null> => {
    const found = await HomeVisitModel.findById(id)
      .populate('createdBy', 'name')
      .lean();
    return found ? toHomeVisit(found) : null;
  },

  update: async (id: string, updates: Partial<HomeVisit>): Promise<HomeVisit | null> => {
    const updated = await HomeVisitModel.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    })
      .populate('createdBy', 'name')
      .lean();
    return updated ? toHomeVisit(updated) : null;
  },

  delete: async (id: string): Promise<boolean> => {
    const res = await HomeVisitModel.findByIdAndDelete(id);
    return Boolean(res);
  },
};

function toHomeVisit(doc: any): HomeVisit {
  return {
    id: doc._id.toString(),
    patientName: doc.patientName,
    address: doc.address,
    visitDate: doc.visitDate,
    notes: doc.notes,
    createdAt: doc.createdAt,
    createdBy: doc.createdBy && typeof doc.createdBy === 'object' && 'name' in doc.createdBy
      ? (doc.createdBy as any).name
      : doc.createdBy?.toString(),
  };
}


