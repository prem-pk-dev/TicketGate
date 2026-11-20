export type EventItem = {
  id: string; title: string; slug: string; category: string; description?: string | null;
  poster_url?: string | null; language?: string | null; age_rating?: string | null;
};
export type City = { id: string; name: string; slug: string; state: string };