use std::env;
use std::process::{Command, Stdio};

const COLOR_RESET: &str = "\x1b[0m";
const COLOR_BOLD: &str = "\x1b[1m";
const COLOR_MAUVE: &str = "\x1b[38;2;203;166;247m";
const COLOR_BLUE: &str = "\x1b[38;2;137;180;250m";
const COLOR_GREEN: &str = "\x1b[38;2;166;227;161m";
const COLOR_PEACH: &str = "\x1b[38;2;250;179;135m";
const COLOR_CYAN: &str = "\x1b[38;2;137;220;235m";
const COLOR_RED: &str = "\x1b[38;2;243;139;168m";
const COLOR_GRAY: &str = "\x1b[38;2;147;153;178m";

fn print_banner() {
    println!("{COLOR_MAUVE}{COLOR_BOLD}╔════════════════════════════════════════════════════════════╗{COLOR_RESET}");
    println!("{COLOR_MAUVE}{COLOR_BOLD}║      🚀 STEvE_OS NAS Edition — CLI Manager (Rust)          ║{COLOR_RESET}");
    println!("{COLOR_MAUVE}{COLOR_BOLD}╚════════════════════════════════════════════════════════════╝{COLOR_RESET}\n");
}

fn print_help() {
    print_banner();
    println!("{COLOR_BOLD}USAGE:{COLOR_RESET}");
    println!("  steveos-cli <COMMANDE> [ARGUMENTS]\n");
    println!("{COLOR_BOLD}COMMANDES DISPONIBLES:{COLOR_RESET}");
    println!("  {COLOR_GREEN}probe{COLOR_RESET}   [user@ip]      Diagnostiquer le matériel du NAS distant (CPU, GPU, disques)");
    println!("  {COLOR_CYAN}copy-id{COLOR_RESET} [user@ip]      Copier votre clé SSH locale sur le NAS");
    println!("  {COLOR_BLUE}status{COLOR_RESET}                 Afficher la configuration NixOS évaluée (ports, GPU, services)");
    println!("  {COLOR_PEACH}deploy{COLOR_RESET}  [user@ip]      Déployer la configuration NixOS sur le NAS distant");
    println!("  {COLOR_GRAY}help{COLOR_RESET}                   Afficher ce message d'aide\n");
    println!("{COLOR_BOLD}EXEMPLES:{COLOR_RESET}");
    println!("  cargo run -- probe chomiam@192.168.1.139");
    println!("  cargo run -- deploy chomiam@192.168.1.139");
}

fn cmd_probe(target: &str) {
    print_banner();
    println!("{COLOR_CYAN}🔍 Lancement du diagnostic matériel sur {COLOR_BOLD}{target}{COLOR_RESET}...\n");

    let script = r#"
echo -e "\n\x1b[1;36m=== [1/5] PROCESSEUR (CPU) ===\x1b[0m"
lscpu | grep -E 'Model name|Architecture|CPU\(s\):|Thread\(s\) per core' || true

echo -e "\n\x1b[1;35m=== [2/5] CONTRÔLEUR GRAPHIQUE & GPU (Transcodage) ===\x1b[0m"
lspci -nnk | grep -iA3 -E "vga|3d|display" || echo "Aucun GPU PCI spécifique détecté"
if [ -d /dev/dri ]; then
    echo -e "\x1b[32m✔ Périphériques DRM présents :\x1b[0m"
    ls -l /dev/dri
else
    echo -e "\x1b[33m⚠ /dev/dri absent (pas d'accélération matérielle active)\x1b[0m"
fi

echo -e "\n\x1b[1;32m=== [3/5] DISQUES & VOLUMES (Stockage) ===\x1b[0m"
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS,MODEL

echo -e "\n\x1b[1;34m=== [4/5] CARTES RÉSEAU & ADRESSES IP ===\x1b[0m"
ip -brief address

echo -e "\n\x1b[1;33m=== [5/5] SYSTÈME D'EXPLOITATION ACTUEL ===\x1b[0m"
uname -a
if [ -f /etc/os-release ]; then
    grep -E 'PRETTY_NAME|ID|VERSION' /etc/os-release
fi
"#;

    let status = Command::new("ssh")
        .arg("-t")
        .arg(target)
        .arg("bash")
        .stdin(Stdio::piped())
        .spawn()
        .and_then(|mut child| {
            use std::io::Write;
            if let Some(mut stdin) = child.stdin.take() {
                let _ = stdin.write_all(script.as_bytes());
            }
            child.wait()
        });

    match status {
        Ok(s) if s.success() => {
            println!("\n{COLOR_GREEN}✔ Diagnostic terminé avec succès sur {target}.{COLOR_RESET}");
        }
        Ok(s) => {
            eprintln!("\n{COLOR_RED}✘ La commande SSH s'est terminée avec le code : {}{COLOR_RESET}", s.code().unwrap_or(-1));
        }
        Err(e) => {
            eprintln!("\n{COLOR_RED}✘ Impossible d'exécuter la commande SSH : {e}{COLOR_RESET}");
            eprintln!("{COLOR_GRAY}Conseil : vérifiez que votre clé SSH est autorisée via : steveos-cli copy-id {target}{COLOR_RESET}");
        }
    }
}

fn cmd_copy_id(target: &str) {
    print_banner();
    println!("{COLOR_CYAN}🔑 Envoi de votre clé SSH vers {COLOR_BOLD}{target}{COLOR_RESET}...\n");

    let status = Command::new("ssh-copy-id")
        .arg(target)
        .status();

    match status {
        Ok(s) if s.success() => {
            println!("\n{COLOR_GREEN}✔ Clé SSH copiée avec succès ! Vous pouvez maintenant utiliser 'probe' et 'deploy' sans saisir de mot de passe.{COLOR_RESET}");
        }
        _ => {
            eprintln!("\n{COLOR_RED}✘ Échec lors de la copie de la clé SSH.{COLOR_RESET}");
        }
    }
}

fn cmd_status() {
    print_banner();
    println!("{COLOR_BLUE}📊 Évaluation de la configuration NixOS locale (STEvE_OS NAS Edition)...{COLOR_RESET}\n");

    let repo_root = env::current_dir().unwrap_or_else(|_| std::path::PathBuf::from("."));

    // 1. Version NixOS
    println!("{COLOR_BOLD}1. Version de base Nixpkgs :{COLOR_RESET}");
    let _ = Command::new("nix")
        .args(["eval", "--raw"])
        .arg(format!("{}/#nixosConfigurations.nas.config.system.nixos.version", repo_root.display()))
        .status();
    println!("\n");

    // 2. Pilote GPU
    println!("{COLOR_BOLD}2. Pilote GPU & Transcodage configuré :{COLOR_RESET}");
    let _ = Command::new("nix")
        .args(["eval", "--raw"])
        .arg(format!("{}/#nixosConfigurations.nas.config.steveos.hardware.gpu", repo_root.display()))
        .status();
    println!("\n");

    // 3. Pare-feu TCP
    println!("{COLOR_BOLD}3. Ports TCP autorisés (Pare-feu modulaire) :{COLOR_RESET}");
    let _ = Command::new("nix")
        .args(["eval"])
        .arg(format!("{}/#nixosConfigurations.nas.config.networking.firewall.allowedTCPPorts", repo_root.display()))
        .status();
    println!();

    // 4. Pare-feu UDP
    println!("{COLOR_BOLD}4. Ports UDP autorisés (Pare-feu modulaire) :{COLOR_RESET}");
    let _ = Command::new("nix")
        .args(["eval"])
        .arg(format!("{}/#nixosConfigurations.nas.config.networking.firewall.allowedUDPPorts", repo_root.display()))
        .status();
    println!();
}

fn cmd_deploy(target: &str) {
    print_banner();
    println!("{COLOR_PEACH}🚀 Déploiement NixOS à distance vers {COLOR_BOLD}{target}{COLOR_RESET}...\n");

    let repo_root = env::current_dir().unwrap_or_else(|_| std::path::PathBuf::from("."));
    let flake_arg = format!(".#nas");

    let status = Command::new("nixos-rebuild")
        .arg("switch")
        .arg("--flake")
        .arg(flake_arg)
        .arg("--target-host")
        .arg(target)
        .arg("--use-remote-sudo")
        .arg("--show-trace")
        .current_dir(repo_root)
        .status();

    match status {
        Ok(s) if s.success() => {
            println!("\n{COLOR_GREEN}✔ Déploiement de STEvE_OS NAS Edition terminé avec succès !{COLOR_RESET}");
        }
        Ok(s) => {
            eprintln!("\n{COLOR_RED}✘ Le déploiement a échoué avec le code : {}{COLOR_RESET}", s.code().unwrap_or(-1));
        }
        Err(e) => {
            eprintln!("\n{COLOR_RED}✘ Erreur d'exécution de nixos-rebuild : {e}{COLOR_RESET}");
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        print_help();
        return;
    }

    match args[1].as_str() {
        "probe" => {
            let target = args.get(2).map(|s| s.as_str()).unwrap_or("chomiam@192.168.1.139");
            cmd_probe(target);
        }
        "copy-id" => {
            let target = args.get(2).map(|s| s.as_str()).unwrap_or("chomiam@192.168.1.139");
            cmd_copy_id(target);
        }
        "status" => {
            cmd_status();
        }
        "deploy" => {
            let target = args.get(2).map(|s| s.as_str()).unwrap_or("chomiam@192.168.1.139");
            cmd_deploy(target);
        }
        "help" | "--help" | "-h" => {
            print_help();
        }
        unknown => {
            eprintln!("{COLOR_RED}Commande inconnue : {unknown}{COLOR_RESET}\n");
            print_help();
        }
    }
}
