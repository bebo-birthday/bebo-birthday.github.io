# Birthday gift site setup

This site uses GitHub Pages for the public page and Supabase for real password authentication, the gift database, and private video storage. Only the invited owner and recipient accounts can read the gift; only the owner can edit or upload/delete its video.

## 1. Create the Supabase project

Create a project at [Supabase](https://supabase.com/). In **Authentication → Users**, create exactly two users with email addresses and strong passwords. Disable public sign-ups in **Authentication → Settings** so visitors cannot create accounts. Save both account emails and the owner/recipient role mapping.

In **Project Settings → API**, copy the Project URL and the **publishable** key. Never use or publish a secret/service-role key in this repository.

## 2. Create the gift and permissions

Open **SQL Editor**, run [`supabase-setup.sql`](supabase-setup.sql), then choose a UUID (for example `11111111-1111-4111-8111-111111111111`). Replace `YOUR_GIFT_UUID` below with that same UUID. In SQL Editor, insert the gift and the two membership rows using the Auth user UUIDs from **Authentication → Users**:

```sql
insert into public.gifts (id, headline, message)
values ('YOUR_GIFT_UUID', 'my favorite person', 'Happy birthday, my love! 💗');

insert into public.gift_members (gift_id, user_id, role) values
('YOUR_GIFT_UUID', 'OWNER_AUTH_USER_UUID', 'owner'),
('YOUR_GIFT_UUID', 'RECIPIENT_AUTH_USER_UUID', 'recipient');
```

Use the same UUID as the first folder of uploaded video paths. The SQL creates a private `birthday-videos` bucket limited to video formats and 500 MB per file. Supabase account/project storage limits still apply.

## 3. Configure the website

Edit [`config.js`](config.js): set `supabaseUrl`, `supabaseAnonKey`, and `giftId`. `recipientName` only affects the heading. The publishable key is intended for browser use; access is enforced by Auth and row-level/storage policies. Do not put a service-role key in `config.js`.

## 4. Publish with GitHub Pages

Commit `index.html`, `config.js`, and `README.md` (the SQL file is useful to keep with the project), then enable GitHub Pages for the repository. Add the deployed Pages URL to Supabase **Authentication → URL Configuration → Site URL / Redirect URLs**. Use the site URL over HTTPS. Log in with each of the two accounts; the owner can edit, and the recipient can view.

## Security notes

Passwords are handled by Supabase Auth and are not stored by this page. Gift text is protected by database row-level security. The video bucket is private; the page downloads the video through the signed-in user's session instead of publishing a public URL. Transport uses HTTPS, and the provider encrypts stored data at rest. This is provider-managed encryption, not end-to-end encryption: the hosting provider can technically access stored data. Protect the Supabase project account with MFA, keep the service-role key private, and do not enable public sign-ups.
