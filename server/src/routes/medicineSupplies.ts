import { Router, Request, Response } from 'express';
import { medicineSupplyService } from '../services/medicineSupplyService';
import { MedicineSupply } from '../models';

const router = Router();

// GET all medicine supplies
router.get('/', async (req: Request, res: Response) => {
  try {
    const supplies = await medicineSupplyService.getAll();
    res.json(supplies);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch medicine supplies' });
  }
});

// GET medicine supply by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const supply = await medicineSupplyService.getById(req.params.id);
    if (!supply) {
      return res.status(404).json({ error: 'Medicine supply not found' });
    }
    res.json(supply);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch medicine supply' });
  }
});

// POST create new medicine supply
router.post('/', async (req: Request, res: Response) => {
  try {
    const supplyData: MedicineSupply = req.body;
    
    // Basic validation
    if (!supplyData.patientName || !supplyData.medicine || !supplyData.phone) {
      return res.status(400).json({ error: 'Missing required fields: patientName, medicine, phone' });
    }

    const supply = await medicineSupplyService.create(supplyData);
    res.status(201).json(supply);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create medicine supply' });
  }
});

// PUT update medicine supply
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const updates: Partial<MedicineSupply> = req.body;
    const supply = await medicineSupplyService.update(req.params.id, updates);
    
    if (!supply) {
      return res.status(404).json({ error: 'Medicine supply not found' });
    }
    
    res.json(supply);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update medicine supply' });
  }
});

// DELETE medicine supply
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const deleted = await medicineSupplyService.delete(req.params.id);
    
    if (!deleted) {
      return res.status(404).json({ error: 'Medicine supply not found' });
    }
    
    res.json({ message: 'Medicine supply deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete medicine supply' });
  }
});

export default router;

