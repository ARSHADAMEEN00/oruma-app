import { HomeVisit } from '../models';

let homeVisits: HomeVisit[] = [];
let visitIdCounter = 1;

export const homeVisitService = {
  create: async (visit: HomeVisit): Promise<HomeVisit> => {
    const newVisit: HomeVisit = {
      ...visit,
      id: `VISIT${visitIdCounter++}`,
      createdAt: new Date(),
    };
    homeVisits.push(newVisit);
    return newVisit;
  },

  getAll: async (): Promise<HomeVisit[]> => {
    return [...homeVisits];
  },

  getById: async (id: string): Promise<HomeVisit | undefined> => {
    return homeVisits.find(v => v.id === id);
  },

  update: async (id: string, updates: Partial<HomeVisit>): Promise<HomeVisit | null> => {
    const index = homeVisits.findIndex(v => v.id === id);
    if (index === -1) return null;
    
    homeVisits[index] = { ...homeVisits[index], ...updates };
    return homeVisits[index];
  },

  delete: async (id: string): Promise<boolean> => {
    const index = homeVisits.findIndex(v => v.id === id);
    if (index === -1) return false;
    
    homeVisits.splice(index, 1);
    return true;
  },
};

