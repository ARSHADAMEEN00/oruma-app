import { Router, Request, Response } from 'express';
import { equipmentSupplyService } from '../services/equipmentSupplyService';

const router = Router();

// GET all equipment supplies
router.get('/', async (req: Request, res: Response) => {
  try {
    const supplies = await equipmentSupplyService.getAll();
    res.json(supplies);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch equipment supplies' });
  }
});

// GET active supplies
router.get('/active', async (req: Request, res: Response) => {
  try {
    const supplies = await equipmentSupplyService.getActive();
    res.json(supplies);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch active supplies' });
  }
});

// GET equipment supply by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const supply = await equipmentSupplyService.getById(req.params.id);
    if (!supply) {
      return res.status(404).json({ error: 'Equipment supply not found' });
    }
    res.json(supply);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch equipment supply' });
  }
});

// POST create new equipment supply
router.post('/', async (req: Request, res: Response) => {
  try {
    const supplyData = req.body;

    // Basic validation
    if (!supplyData.equipmentId || !supplyData.patientName || !supplyData.patientPhone) {
      return res.status(400).json({ error: 'Missing required fields: equipmentId, patientName, patientPhone' });
    }

    const supply = await equipmentSupplyService.create(supplyData);
    res.status(201).json(supply);
  } catch (error: any) {
    console.error("Create supply error:", error);
    res.status(400).json({ error: error.message || 'Failed to create equipment supply' });
  }
});

// PUT update equipment supply (e.g., mark as returned)
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const updates = req.body;
    const supply = await equipmentSupplyService.update(req.params.id, updates);

    if (!supply) {
      return res.status(404).json({ error: 'Equipment supply not found' });
    }

    res.json(supply);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update equipment supply' });
  }
});

// DELETE equipment supply
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const deleted = await equipmentSupplyService.delete(req.params.id);

    if (!deleted) {
      return res.status(404).json({ error: 'Equipment supply not found' });
    }

    res.json({ message: 'Equipment supply deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete equipment supply' });
  }
});

export default router;
