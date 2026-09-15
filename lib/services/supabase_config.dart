/// Rellenar con los datos de Project Settings > API del proyecto Supabase.
/// La publishable key es pública (segura de commitear); nunca uses la secret key aquí.
const String supabaseUrl = 'https://ssskgmlubgcjvhdmayhp.supabase.co';
const String supabaseAnonKey = 'sb_publishable__XOw6FPg8ehjHfyPY-GhIg_Sq1yZtuv';

/// Base de la app desplegada (Vercel). Se pasa explícitamente como
/// `redirectTo` en los correos de Auth (confirmación, recuperar contraseña)
/// para no depender solo del Site URL configurado en el dashboard de
/// Supabase -- si alguien lo deja en el valor local de desarrollo por
/// error, estas llamadas siguen apuntando al dominio real.
const String appBaseUrl = 'https://app.instriq.org';
