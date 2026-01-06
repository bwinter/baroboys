# Project Backlog (of sorts)

- Configuration is a bit all over the place. Often hardcoded in specific scripts, would be good to be more specific – maybe using direnv? (Upgrade)
  - Even the way the variables work in the make file is a bit confusing. In some cases, they are specified in the Makefile in other cases by the ENV – it's kind of a mixed mess. I think an ideal would be controlled by the environment and maybe have a command for shifting environment and games. As is the makefiles commands are getting kind of overly complex.
- Get save data and game data into S3 / mount. (Security-ish & Reduce Git complexity.)
- Improve the admin page (Make it handle multiple games and add the ability to start game. Later requires a bigger redesign.)
    - Maybe get some React in here?
- Might be interesting to demo K8s, GoLang and React in here. (Future)
    - AI? - Admin console?
    - GoLang - ...
    - Kubernetes? — Running services maybe?
- Tests?
- Pipelines?

# Future

- Is there a better scripts folder layout? (I have already re-designed this once.)

# Done

- Improve game selection (Currently a bit clunky, needing to edit the terraform files directly.)
    - Can now specify via a GAME env var for the makefile's terraform commands.
    - Using custom tfvars files for each game.
- Get emails into secrets (Security)
- Clean up IAM files and workflow (Fix / Upgrade)
    - Reworked this and simplified to a single design.
- Verify Terraform SA can have secrets access removed. (Security)
    - Q: A previous refactor seems to have moved where secrets are read. I should try to streamline this.
    - Q: It's possible I won't be able to due to early cloning needs. It's unclear what SA Packer uses. 🤔
    - A: Removed this SA for now.
    - Q: Maybe part of the refactor here is getting packer to use the vm SA. It is basically being built in a VM. Hmm.
        - N/A: Packer seems to use my local credentials.

