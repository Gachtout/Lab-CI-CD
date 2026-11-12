"""Mutants de l'étape 9 : une contrainte retirée par mutant."""
from mut import json_edit, resub

RS = ".github/rulesets/main.json"
SC = "scripts/setup-github.sh"


def _drop(data, kind):
    data["rules"] = [r for r in data["rules"] if r["type"] != kind]


def c1():
    """ruleset désactivé"""
    json_edit(RS, lambda d: d.update(enforcement="disabled"))


def c2():
    """un rôle peut contourner le ruleset"""
    json_edit(RS, lambda d: d["bypass_actors"].append({"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}))


def c3():
    """réécriture d'historique autorisée"""
    json_edit(RS, lambda d: _drop(d, "non_fast_forward"))


def c4():
    """pull request non obligatoire"""
    json_edit(RS, lambda d: _drop(d, "pull_request"))


def c5():
    """un statut n'est plus requis"""
    def edit(d):
        for rule in d["rules"]:
            if rule["type"] == "required_status_checks":
                rule["parameters"]["required_status_checks"] = [c for c in rule["parameters"]["required_status_checks"] if c["context"] != "plan"]
    json_edit(RS, edit)


def c6():
    """push protection non activée"""
    resub(SC, r"secret_scanning_push_protection", "secret_scanning_validity_checks")


def c7():
    """le script recrée le ruleset à chaque lancement"""
    resub(SC, r'--method PUT ("repos/\$\{repo\}/rulesets/)', r"--method POST \1")
