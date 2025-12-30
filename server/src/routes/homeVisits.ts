import { Router, Request, Response } from 'express';
import { homeVisitService } from '../services/homeVisitService';
import { HomeVisit } from '../models';

const router = Router();

// GET all home visits
router.get('/', async (req: Request, res: Response) => {
  try {
    const visits = await homeVisitService.getAll();
    res.json(visits);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch home visits' });
  }
});

// GET home visit by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const visit = await homeVisitService.getById(req.params.id);
    if (!visit) {
      return res.status(404).json({ error: 'Home visit not found' });
    }
    res.json(visit);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch home visit' });
  }
});

// POST create new home visit
router.post('/', async (req: Request, res: Response) => {
  try {
    const visitData: HomeVisit = req.body;
    
    // Basic validation
    if (!visitData.patientName || !visitData.address || !visitData.visitDate) {
      return res.status(400).json({ error: 'Missing required fields: patientName, address, visitDate' });
    }

    const visit = await homeVisitService.create(visitData);
    res.status(201).json(visit);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create home visit' });
  }
});

// PUT update home visit
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const updates: Partial<HomeVisit> = req.body;
    const visit = await homeVisitService.update(req.params.id, updates);
    
    if (!visit) {
      return res.status(404).json({ error: 'Home visit not found' });
    }
    
    res.json(visit);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update home visit' });
  }
});

// DELETE home visit
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const deleted = await homeVisitService.delete(req.params.id);
    
    if (!deleted) {
      return res.status(404).json({ error: 'Home visit not found' });
    }
    
    res.json({ message: 'Home visit deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete home visit' });
  }
});

export default router;

