# Level/Version for the document
const WRITESBML_DEFAULT_LEVEL = 3
const WRITESBML_DEFAULT_VERSION = 2
# Level/Version/Package version for the package
const WRITESBML_PKG_DEFAULT_LEVEL = 3
const WRITESBML_PKG_DEFAULT_VERSION = 1
const WRITESBML_PKG_DEFAULT_PKGVERSION = 2

## Get pointers for some SBML data structures

function set_gene_product_association_ptr!(
    gene_product_association_ptr::VPtr,
    gpr::GPARef,
)::VPtr
    ccall(
        sbml(:GeneProductRef_setGeneProduct),
        Cint,
        (VPtr, Cstring),
        gene_product_association_ptr,
        gpr.gene_product,
    )
    return gene_product_association_ptr
end

function get_gene_product_association_ptr(gpr::GPARef)::VPtr
    gene_product_association_ptr = ccall(
        sbml(:GeneProductRef_create),
        VPtr,
        (Cuint, Cuint, Cuint),
        WRITESBML_PKG_DEFAULT_LEVEL,
        WRITESBML_PKG_DEFAULT_VERSION,
        WRITESBML_PKG_DEFAULT_PKGVERSION,
    )
    return set_gene_product_association_ptr!(gene_product_association_ptr, gpr)
end

function set_gene_product_association_ptr!(
    gene_product_association_ptr::VPtr,
    gpa::GPAAnd,
)::VPtr
    for term in gpa.terms
        term_ptr = if term isa GPARef
            ccall(
                sbml(:FbcAnd_createGeneProductRef),
                VPtr,
                (VPtr,),
                gene_product_association_ptr,
            )
        elseif term isa GPAAnd
            ccall(sbml(:FbcAnd_createAnd), VPtr, (VPtr,), gene_product_association_ptr)
        elseif term isa GPAOr
            ccall(sbml(:FbcAnd_createOr), VPtr, (VPtr,), gene_product_association_ptr)
        end
        set_gene_product_association_ptr!(term_ptr, term)
    end
    return gene_product_association_ptr
end

function get_gene_product_association_ptr(gpa::GPAAnd)::VPtr
    gene_product_association_ptr = ccall(
        sbml(:FbcAnd_create),
        VPtr,
        (Cuint, Cuint, Cuint),
        WRITESBML_PKG_DEFAULT_LEVEL,
        WRITESBML_PKG_DEFAULT_VERSION,
        WRITESBML_PKG_DEFAULT_PKGVERSION,
    )
    return set_gene_product_association_ptr!(gene_product_association_ptr, gpa)
end

function set_gene_product_association_ptr!(
    gene_product_association_ptr::VPtr,
    gpo::GPAOr,
)::VPtr
    for term in gpo.terms
        term_ptr = if term isa GPARef
            ccall(
                sbml(:FbcOr_createGeneProductRef),
                VPtr,
                (VPtr,),
                gene_product_association_ptr,
            )
        elseif term isa GPAAnd
            ccall(sbml(:FbcOr_createAnd), VPtr, (VPtr,), gene_product_association_ptr)
        elseif term isa GPAOr
            ccall(sbml(:FbcOr_createOr), VPtr, (VPtr,), gene_product_association_ptr)
        end
        set_gene_product_association_ptr!(term_ptr, term)
    end
    return gene_product_association_ptr
end

function get_gene_product_association_ptr(gpo::GPAOr)::VPtr
    gene_product_association_ptr = ccall(
        sbml(:FbcOr_create),
        VPtr,
        (Cuint, Cuint, Cuint),
        WRITESBML_PKG_DEFAULT_LEVEL,
        WRITESBML_PKG_DEFAULT_VERSION,
        WRITESBML_PKG_DEFAULT_PKGVERSION,
    )
    return set_gene_product_association_ptr!(gene_product_association_ptr, gpo)
end

function get_rule_ptr(r::AlgebraicRule)::VPtr
    algebraicrule_ptr = ccall(
        sbml(:AlgebraicRule_create),
        VPtr,
        (Cuint, Cuint),
        WRITESBML_DEFAULT_LEVEL,
        WRITESBML_DEFAULT_VERSION,
    )
    ccall(
        sbml(:AlgebraicRule_setMath),
        Cint,
        (VPtr, VPtr),
        algebraicrule_ptr,
        get_astnode_ptr(r.math),
    )
    return algebraicrule_ptr
end

function get_rule_ptr(r::Union{AssignmentRule,RateRule})::VPtr
    rule_ptr = if r isa AssignmentRule
        ccall(
            sbml(:Rule_createAssignment),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
    else
        ccall(
            sbml(:Rule_createRate),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
    end
    ccall(sbml(:Rule_setVariable), Cint, (VPtr, Cstring), rule_ptr, r.variable)
    ccall(sbml(:Rule_setMath), Cint, (VPtr, VPtr), rule_ptr, get_astnode_ptr(r.math))
    return rule_ptr
end

function set_parameter_ptr!(parameter_ptr::VPtr, id::String, parameter::Parameter)::VPtr
    ccall(sbml(:Parameter_setId), Cint, (VPtr, Cstring), parameter_ptr, id)
    isnothing(parameter.name) || ccall(
        sbml(:Parameter_setName),
        Cint,
        (VPtr, Cstring),
        parameter_ptr,
        parameter.name,
    )
    isnothing(parameter.value) || ccall(
        sbml(:Parameter_setValue),
        Cint,
        (VPtr, Cdouble),
        parameter_ptr,
        parameter.value,
    )
    isnothing(parameter.units) || ccall(
        sbml(:Parameter_setUnits),
        Cint,
        (VPtr, Cstring),
        parameter_ptr,
        parameter.units,
    )
    isnothing(parameter.constant) || ccall(
        sbml(:Parameter_setConstant),
        Cint,
        (VPtr, Cint),
        parameter_ptr,
        Cint(parameter.constant),
    )
    return parameter_ptr
end

function get_parameter_ptr(id::String, parameter::Parameter)::VPtr
    parameter_ptr = ccall(
        sbml(:Parameter_create),
        VPtr,
        (Cuint, Cuint),
        WRITESBML_DEFAULT_LEVEL,
        WRITESBML_DEFAULT_VERSION,
    )
    return set_parameter_ptr!(parameter_ptr, id, parameter)
end

## Write the model

function model_to_sbml!(doc::VPtr, mdl::Model)::VPtr
    # Create the model pointer
    model = ccall(sbml(:SBMLDocument_createModel), VPtr, (VPtr,), doc)
    fbc_plugin = ccall(sbml(:SBase_getPlugin), VPtr, (VPtr, Cstring), model, "fbc")
    fbc_plugin == C_NULL ||
        isempty(mdl.gene_products) ||
        isempty(mdl.objectives) ||
        isempty(mdl.species) ||
        ccall(sbml(:FbcModelPlugin_setStrict), Cint, (VPtr, Cint), fbc_plugin, true)

    # Set ids and name
    isnothing(mdl.id) || ccall(sbml(:Model_setId), Cint, (VPtr, Cstring), model, mdl.id)
    isnothing(mdl.metaid) ||
        ccall(sbml(:SBase_setMetaId), Cint, (VPtr, Cstring), model, mdl.metaid)
    isnothing(mdl.name) ||
        ccall(sbml(:Model_setName), Cint, (VPtr, Cstring), model, mdl.name)

    # Add parameters
    for (id, parameter) in mdl.parameters
        parameter_ptr = ccall(sbml(:Model_createParameter), VPtr, (VPtr,), model)
        set_parameter_ptr!(parameter_ptr, id, parameter)
    end

    # Add units
    for (name, units) in mdl.units
        res = ccall(
            sbml(:Model_addUnitDefinition),
            Cint,
            (VPtr, VPtr),
            model,
            unit_definition(name, units),
        )
        !iszero(res) &&
            @warn "Failed to add unit \"$(name)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add compartments
    for (id, compartment) in mdl.compartments
        compartment_t = ccall(
            sbml(:Compartment_create),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
        ccall(sbml(:Compartment_setId), Cint, (VPtr, Cstring), compartment_t, id)
        isnothing(compartment.name) || ccall(
            sbml(:Compartment_setName),
            Cint,
            (VPtr, Cstring),
            compartment_t,
            compartment.name,
        )
        isnothing(compartment.constant) || ccall(
            sbml(:Compartment_setConstant),
            Cint,
            (VPtr, Cint),
            compartment_t,
            Cint(compartment.constant),
        )
        isnothing(compartment.spatial_dimensions) || ccall(
            sbml(:Compartment_setSpatialDimensions),
            Cint,
            (VPtr, Cuint),
            compartment_t,
            Cuint(compartment.spatial_dimensions),
        )
        isnothing(compartment.size) || ccall(
            sbml(:Compartment_setSize),
            Cint,
            (VPtr, Cdouble),
            compartment_t,
            Cdouble(compartment.size),
        )
        isnothing(compartment.units) || ccall(
            sbml(:Compartment_setUnits),
            Cint,
            (VPtr, Cstring),
            compartment_t,
            compartment.units,
        )
        isnothing(compartment.notes) || ccall(
            sbml(:SBase_setNotesString),
            Cint,
            (VPtr, Cstring),
            compartment_t,
            compartment.notes,
        )
        isnothing(compartment.annotation) || ccall(
            sbml(:SBase_setAnnotationString),
            Cint,
            (VPtr, Cstring),
            compartment_t,
            compartment.annotation,
        )
        res = ccall(sbml(:Model_addCompartment), Cint, (VPtr, VPtr), model, compartment_t)
        !iszero(res) &&
            @warn "Failed to add compartment \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add gene products
    fbc_plugin == C_NULL ||
        isempty(mdl.gene_products) ||
        ccall(sbml(:FbcModelPlugin_setStrict), Cint, (VPtr, Cint), fbc_plugin, true)
    for (id, gene_product) in mdl.gene_products
        geneproduct_ptr = ccall(
            sbml(:GeneProduct_create),
            VPtr,
            (Cuint, Cuint, Cuint),
            WRITESBML_PKG_DEFAULT_LEVEL,
            WRITESBML_PKG_DEFAULT_VERSION,
            WRITESBML_PKG_DEFAULT_PKGVERSION,
        )
        ccall(sbml(:GeneProduct_setId), Cint, (VPtr, Cstring), geneproduct_ptr, id)
        ccall(
            sbml(:GeneProduct_setLabel),
            Cint,
            (VPtr, Cstring),
            geneproduct_ptr,
            gene_product.label,
        )
        isnothing(gene_product.name) || ccall(
            sbml(:GeneProduct_setName),
            Cint,
            (VPtr, Cstring),
            geneproduct_ptr,
            gene_product.name,
        )
        isnothing(gene_product.metaid) || ccall(
            sbml(:SBase_setMetaId),
            Cint,
            (VPtr, Cstring),
            geneproduct_ptr,
            gene_product.metaid,
        )
        isnothing(gene_product.notes) || ccall(
            sbml(:SBase_setNotesString),
            Cint,
            (VPtr, Cstring),
            geneproduct_ptr,
            gene_product.notes,
        )
        isnothing(gene_product.annotation) || ccall(
            sbml(:SBase_setAnnotationString),
            Cint,
            (VPtr, Cstring),
            geneproduct_ptr,
            gene_product.annotation,
        )
        res = ccall(
            sbml(:FbcModelPlugin_addGeneProduct),
            Cint,
            (VPtr, VPtr),
            fbc_plugin,
            geneproduct_ptr,
        )
        !iszero(res) &&
            @warn "Failed to add gene product \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add initial assignments
    for (symbol, math) in mdl.initial_assignments
        initialassignment_t = ccall(
            sbml(:InitialAssignment_create),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
        ccall(
            sbml(:InitialAssignment_setSymbol),
            Cint,
            (VPtr, Cstring),
            initialassignment_t,
            symbol,
        )
        ccall(
            sbml(:InitialAssignment_setMath),
            Cint,
            (VPtr, VPtr),
            initialassignment_t,
            get_astnode_ptr(math),
        )
        res = ccall(
            sbml(:Model_addInitialAssignment),
            Cint,
            (VPtr, VPtr),
            model,
            initialassignment_t,
        )
        !iszero(res) &&
            @warn "Failed to add initial assignment \"$(symbol)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add constraints
    for constraint in mdl.constraints
        constraint_t = ccall(
            sbml(:Constraint_create),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
        # Note: this probably incorrect because our `Constraint` lost the XML namespace of the
        # message, also we don't have an easy way to test this because no test file uses constraints.
        message = ccall(sbml(:XMLNode_createTextNode), VPtr, (Cstring,), constraint.message)
        ccall(sbml(:Constraint_setMessage), Cint, (VPtr, VPtr), constraint_t, message)
        ccall(
            sbml(:Constraint_setMath),
            Cint,
            (VPtr, VPtr),
            constraint_t,
            get_astnode_ptr(constraint.math),
        )
        res = ccall(sbml(:Model_addConstraint), Cint, (VPtr, VPtr), model, constraint_t)
        !iszero(res) && @warn "Failed to add constrain: $(OPERATION_RETURN_VALUES[res])"
    end

    # Add reactions
    for (id, reaction) in mdl.reactions
        reaction_ptr = ccall(sbml(:Model_createReaction), VPtr, (VPtr,), model)
        ccall(sbml(:Reaction_setId), Cint, (VPtr, Cstring), reaction_ptr, id)
        ccall(
            sbml(:Reaction_setReversible),
            Cint,
            (VPtr, Cint),
            reaction_ptr,
            reaction.reversible,
        )
        isnothing(reaction.name) || ccall(
            sbml(:Reaction_setName),
            Cint,
            (VPtr, Cstring),
            reaction_ptr,
            reaction.name,
        )
        for (species, stoichiometry) in reaction.reactants
            reactant_ptr =
                ccall(sbml(:Reaction_createReactant), VPtr, (VPtr,), reaction_ptr)
            ccall(
                sbml(:SpeciesReference_setSpecies),
                Cint,
                (VPtr, Cstring),
                reactant_ptr,
                species,
            )
            ccall(
                sbml(:SpeciesReference_setStoichiometry),
                Cint,
                (VPtr, Cdouble),
                reactant_ptr,
                stoichiometry,
            )
            # Assume constant reactant for the time being
            ccall(
                sbml(:SpeciesReference_setConstant),
                Cint,
                (VPtr, Cint),
                reactant_ptr,
                true,
            )
        end
        for (species, stoichiometry) in reaction.products
            product_ptr = ccall(sbml(:Reaction_createProduct), VPtr, (VPtr,), reaction_ptr)
            ccall(
                sbml(:SpeciesReference_setSpecies),
                Cint,
                (VPtr, Cstring),
                product_ptr,
                species,
            )
            ccall(
                sbml(:SpeciesReference_setStoichiometry),
                Cint,
                (VPtr, Cdouble),
                product_ptr,
                stoichiometry,
            )
            # Assume constant product for the time being
            ccall(
                sbml(:SpeciesReference_setConstant),
                Cint,
                (VPtr, Cint),
                product_ptr,
                true,
            )
        end
        if !isempty(reaction.kinetic_parameters) || !isnothing(reaction.kinetic_math)
            kinetic_law_ptr =
                ccall(sbml(:Reaction_createKineticLaw), VPtr, (VPtr,), reaction_ptr)
            for (id, parameter) in reaction.kinetic_parameters
                error()
                parameter_ptr =
                    ccall(sbml(:KineticLaw_createParameter), VPtr, (VPtr,), kinetic_law_ptr)
                set_parameter_ptr!(parameter_ptr, id, parameter)
            end
            isnothing(reaction.kinetic_math) || ccall(
                sbml(:KineticLaw_setMath),
                Cint,
                (VPtr, VPtr),
                kinetic_law_ptr,
                get_astnode_ptr(reaction.kinetic_math),
            )
        end
        if !isnothing(reaction.lower_bound) || !isnothing(reaction.upper_bound)
            reaction_fbc_ptr =
                ccall(sbml(:SBase_getPlugin), VPtr, (VPtr, Cstring), reaction_ptr, "fbc")
            isnothing(reaction.lower_bound) || ccall(
                sbml(:FbcReactionPlugin_setLowerFluxBound),
                Cint,
                (VPtr, Cstring),
                reaction_fbc_ptr,
                reaction.lower_bound,
            )
            isnothing(reaction.upper_bound) || ccall(
                sbml(:FbcReactionPlugin_setUpperFluxBound),
                Cint,
                (VPtr, Cstring),
                reaction_fbc_ptr,
                reaction.upper_bound,
            )
            isnothing(reaction.gene_product_association) || ccall(
                sbml(:FbcReactionPlugin_setGeneProductAssociation),
                Cint,
                (VPtr, VPtr),
                reaction_fbc_ptr,
                get_gene_product_association_ptr(reaction.gene_product_association),
            )
        end
        isnothing(reaction.notes) || ccall(
            sbml(:SBase_setNotesString),
            Cint,
            (VPtr, Cstring),
            reaction_ptr,
            reaction.notes,
        )
        isnothing(reaction.annotation) || ccall(
            sbml(:SBase_setAnnotationString),
            Cint,
            (VPtr, Cstring),
            reaction_ptr,
            reaction.annotation,
        )
    end

    # Add objectives
    fbc_plugin == C_NULL ||
        isempty(mdl.objectives) ||
        ccall(sbml(:FbcModelPlugin_setStrict), Cint, (VPtr, Cint), fbc_plugin, true)
    for (id, objective) in mdl.objectives
        objective_ptr = ccall(
            sbml(:Objective_create),
            VPtr,
            (Cuint, Cuint, Cuint),
            WRITESBML_PKG_DEFAULT_LEVEL,
            WRITESBML_PKG_DEFAULT_VERSION,
            WRITESBML_PKG_DEFAULT_PKGVERSION,
        )
        ccall(sbml(:Objective_setId), Cint, (VPtr, Cstring), objective_ptr, id)
        ccall(
            sbml(:Objective_setType),
            Cint,
            (VPtr, Cstring),
            objective_ptr,
            objective.type,
        )
        for (reaction, coefficient) in objective.flux_objectives
            fluxobjective_ptr = ccall(
                sbml(:FluxObjective_create),
                VPtr,
                (Cuint, Cuint, Cuint),
                WRITESBML_PKG_DEFAULT_LEVEL,
                WRITESBML_PKG_DEFAULT_VERSION,
                WRITESBML_PKG_DEFAULT_PKGVERSION,
            )
            ccall(
                sbml(:FluxObjective_setReaction),
                Cint,
                (VPtr, Cstring),
                fluxobjective_ptr,
                reaction,
            )
            ccall(
                sbml(:FluxObjective_setCoefficient),
                Cint,
                (VPtr, Cdouble),
                fluxobjective_ptr,
                coefficient,
            )
            res = ccall(
                sbml(:Objective_addFluxObjective),
                Cint,
                (VPtr, VPtr),
                objective_ptr,
                fluxobjective_ptr,
            )
            !iszero(res) &&
                @warn "Failed to add flux objective \"$(reaction)\": $(OPERATION_RETURN_VALUES[res])"
        end
        res = ccall(
            sbml(:FbcModelPlugin_addObjective),
            Cint,
            (VPtr, VPtr),
            fbc_plugin,
            objective_ptr,
        )
        !iszero(res) &&
            @warn "Failed to add objective \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end
    fbc_plugin == C_NULL || ccall(
        sbml(:FbcModelPlugin_setActiveObjectiveId),
        Cint,
        (VPtr, Cstring),
        fbc_plugin,
        mdl.active_objective,
    )

    # Add species
    fbc_plugin == C_NULL ||
        isempty(mdl.species) ||
        ccall(sbml(:FbcModelPlugin_setStrict), Cint, (VPtr, Cint), fbc_plugin, true)
    for (id, species) in mdl.species
        species_ptr = ccall(sbml(:Model_createSpecies), VPtr, (VPtr,), model)
        ccall(sbml(:Species_setId), Cint, (VPtr, Cstring), species_ptr, id)
        isnothing(species.name) ||
            ccall(sbml(:Species_setName), Cint, (VPtr, Cstring), species_ptr, species.name)
        isnothing(species.compartment) || ccall(
            sbml(:Species_setCompartment),
            Cint,
            (VPtr, Cstring),
            species_ptr,
            species.compartment,
        )
        isnothing(species.boundary_condition) || ccall(
            sbml(:Species_setBoundaryCondition),
            Cint,
            (VPtr, Cint),
            species_ptr,
            species.boundary_condition,
        )
        species_fbc_ptr =
            ccall(sbml(:SBase_getPlugin), VPtr, (VPtr, Cstring), species_ptr, "fbc")
        if species_fbc_ptr != C_NULL
            isnothing(species.formula) || ccall(
                sbml(:FbcSpeciesPlugin_setChemicalFormula),
                Cint,
                (VPtr, Cstring),
                species_fbc_ptr,
                species.formula,
            )
            isnothing(species.charge) || ccall(
                sbml(:FbcSpeciesPlugin_setCharge),
                Cint,
                (VPtr, Cint),
                species_fbc_ptr,
                species.charge,
            )
        end
        isnothing(species.initial_amount) || ccall(
            sbml(:Species_setInitialAmount),
            Cint,
            (VPtr, Cdouble),
            species_ptr,
            species.initial_amount,
        )
        isnothing(species.initial_concentration) || ccall(
            sbml(:Species_setInitialConcentration),
            Cint,
            (VPtr, Cdouble),
            species_ptr,
            species.initial_concentration,
        )
        isnothing(species.substance_units) || ccall(
            sbml(:Species_setSubstanceUnits),
            Cint,
            (VPtr, Cstring),
            species_ptr,
            species.substance_units,
        )
        isnothing(species.only_substance_units) || ccall(
            sbml(:Species_setHasOnlySubstanceUnits),
            Cint,
            (VPtr, Cint),
            species_ptr,
            species.only_substance_units,
        )
        isnothing(species.constant) || ccall(
            sbml(:Species_setConstant),
            Cint,
            (VPtr, Cint),
            species_ptr,
            species.constant,
        )
        isnothing(species.metaid) || ccall(
            sbml(:SBase_setMetaId),
            Cint,
            (VPtr, Cstring),
            species_ptr,
            species.metaid,
        )
        isnothing(species.notes) || ccall(
            sbml(:SBase_setNotesString),
            Cint,
            (VPtr, Cstring),
            species_ptr,
            species.notes,
        )
        isnothing(species.annotation) || ccall(
            sbml(:SBase_setAnnotationString),
            Cint,
            (VPtr, Cstring),
            species_ptr,
            species.annotation,
        )
    end

    # Add function definitions
    for (id, func_def) in mdl.function_definitions
        functiondefinition_t = ccall(
            sbml(:FunctionDefinition_create),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
        ccall(
            sbml(:FunctionDefinition_setId),
            Cint,
            (VPtr, Cstring),
            functiondefinition_t,
            id,
        )
        isnothing(func_def.name) || ccall(
            sbml(:FunctionDefinition_setName),
            Cint,
            (VPtr, Cstring),
            functiondefinition_t,
            func_def.name,
        )
        isnothing(func_def.body) || ccall(
            sbml(:FunctionDefinition_setMath),
            Cint,
            (VPtr, VPtr),
            functiondefinition_t,
            get_astnode_ptr(func_def.body),
        )
        isnothing(func_def.notes) || ccall(
            sbml(:SBase_setNotesString),
            Cint,
            (VPtr, Cstring),
            functiondefinition_t,
            func_def.notes,
        )
        isnothing(func_def.annotation) || ccall(
            sbml(:SBase_setAnnotationString),
            Cint,
            (VPtr, Cstring),
            functiondefinition_t,
            func_def.annotation,
        )
        res = ccall(
            sbml(:Model_addFunctionDefinition),
            Cint,
            (VPtr, VPtr),
            model,
            functiondefinition_t,
        )
        !iszero(res) &&
            @warn "Failed to add function definition \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add rules
    for rule in mdl.rules
        rule_t = get_rule_ptr(rule)
        res = ccall(sbml(:Model_addRule), Cint, (VPtr, VPtr), model, rule_t)
        !iszero(res) && @warn "Failed to add rule: $(OPERATION_RETURN_VALUES[res])"
    end

    # Add events
    for (id, event) in mdl.events
        event_t = ccall(
            sbml(:Event_create),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
        ccall(sbml(:Event_setId), Cint, (VPtr, Cstring), event_t, id)
        ccall(
            sbml(:Event_setUseValuesFromTriggerTime),
            Cint,
            (VPtr, Cint),
            event_t,
            event.use_values_from_trigger_time,
        )
        isnothing(event.name) ||
            ccall(sbml(:Event_setName), Cint, (VPtr, Cstring), event_t, event.name)
        if !isnothing(event.trigger)
            trigger_t = ccall(
                sbml(:Trigger_create),
                VPtr,
                (Cuint, Cuint),
                WRITESBML_DEFAULT_LEVEL,
                WRITESBML_DEFAULT_VERSION,
            )
            ccall(
                sbml(:Trigger_setPersistent),
                Cint,
                (VPtr, Cint),
                trigger_t,
                event.trigger.persistent,
            )
            ccall(
                sbml(:Trigger_setInitialValue),
                Cint,
                (VPtr, Cint),
                trigger_t,
                event.trigger.initial_value,
            )
            isnothing(event.trigger.math) || ccall(
                sbml(:Trigger_setMath),
                Cint,
                (VPtr, VPtr),
                trigger_t,
                get_astnode_ptr(event.trigger.math),
            )
            ccall(sbml(:Event_setTrigger), Cint, (VPtr, VPtr), event_t, trigger_t)
        end
        if !isnothing(event.event_assignments)
            for event_assignment in event.event_assignments
                event_assignment_t = ccall(
                    sbml(:EventAssignment_create),
                    VPtr,
                    (Cuint, Cuint),
                    WRITESBML_DEFAULT_LEVEL,
                    WRITESBML_DEFAULT_VERSION,
                )
                ccall(
                    sbml(:EventAssignment_setVariable),
                    Cint,
                    (VPtr, Cstring),
                    event_assignment_t,
                    event_assignment.variable,
                )
                isnothing(event_assignment.math) || ccall(
                    sbml(:EventAssignment_setMath),
                    Cint,
                    (VPtr, VPtr),
                    event_assignment_t,
                    get_astnode_ptr(event_assignment.math),
                )
                ccall(
                    sbml(:Event_addEventAssignment),
                    Cint,
                    (VPtr, VPtr),
                    event_t,
                    event_assignment_t,
                )
            end
        end
        res = ccall(sbml(:Model_addEvent), Cint, (VPtr, VPtr), model, event_t)
        !iszero(res) &&
            @warn "Failed to add event \"$(id)\": $(OPERATION_RETURN_VALUES[res])"
    end

    # Add conversion factor
    isnothing(mdl.conversion_factor) || ccall(
        sbml(:Model_setConversionFactor),
        Cint,
        (VPtr, Cstring),
        model,
        mdl.conversion_factor,
    )

    # Add other units attributes
    isnothing(mdl.area_units) ||
        ccall(sbml(:Model_setAreaUnits), Cint, (VPtr, Cstring), model, mdl.area_units)
    isnothing(mdl.extent_units) ||
        ccall(sbml(:Model_setExtentUnits), Cint, (VPtr, Cstring), model, mdl.extent_units)
    isnothing(mdl.length_units) ||
        ccall(sbml(:Model_setLengthUnits), Cint, (VPtr, Cstring), model, mdl.length_units)
    isnothing(mdl.substance_units) || ccall(
        sbml(:Model_setSubstanceUnits),
        Cint,
        (VPtr, Cstring),
        model,
        mdl.substance_units,
    )
    isnothing(mdl.time_units) ||
        ccall(sbml(:Model_setTimeUnits), Cint, (VPtr, Cstring), model, mdl.time_units)
    isnothing(mdl.volume_units) ||
        ccall(sbml(:Model_setVolumeUnits), Cint, (VPtr, Cstring), model, mdl.volume_units)

    # Notes and annotations
    isnothing(mdl.notes) ||
        ccall(sbml(:SBase_setNotesString), Cint, (VPtr, Cstring), model, mdl.notes)
    isnothing(mdl.annotation) || ccall(
        sbml(:SBase_setAnnotationString),
        Cint,
        (VPtr, Cstring),
        model,
        mdl.annotation,
    )

    # We can finally return the model
    return model
end

function _create_doc(mdl::Model)::VPtr
    doc = if isempty(mdl.gene_products) && isempty(mdl.objectives) && isempty(mdl.species)
        ccall(
            sbml(:SBMLDocument_createWithLevelAndVersion),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
    else
        # Get fbc registry entry
        sbmlext = ccall(sbml(:SBMLExtensionRegistry_getExtension), VPtr, (Cstring,), "fbc")
        # create the sbml namespaces object with fbc
        fbc = ccall(sbml(:XMLNamespaces_create), VPtr, ())
        # create the sbml namespaces object with fbc
        uri = ccall(
            sbml(:SBMLExtension_getURI),
            Cstring,
            (VPtr, Cuint, Cuint, Cuint),
            sbmlext,
            WRITESBML_PKG_DEFAULT_LEVEL,
            WRITESBML_PKG_DEFAULT_VERSION,
            WRITESBML_PKG_DEFAULT_PKGVERSION,
        )
        ccall(sbml(:XMLNamespaces_add), Cint, (VPtr, Cstring, Cstring), fbc, uri, "fbc")
        # Create SBML namespace with fbc package
        sbmlns = ccall(
            sbml(:SBMLNamespaces_create),
            VPtr,
            (Cuint, Cuint),
            WRITESBML_DEFAULT_LEVEL,
            WRITESBML_DEFAULT_VERSION,
        )
        ccall(sbml(:SBMLNamespaces_addPackageNamespaces), Cint, (VPtr, VPtr), sbmlns, fbc)
        # Create document from SBML namespace
        d = ccall(sbml(:SBMLDocument_createWithSBMLNamespaces), VPtr, (VPtr,), sbmlns)
        # Do not require fbc package
        ccall(
            sbml(:SBMLDocument_setPackageRequired),
            Cint,
            (VPtr, Cstring, Cint),
            d,
            "fbc",
            false,
        )
        d
    end
    return doc
end

function writeSBML(mdl::Model, fn::String)
    doc = _create_doc(mdl)
    model = try
        model_to_sbml!(doc, mdl)
        res = ccall(sbml(:writeSBML), Cint, (VPtr, Cstring), doc, fn)
        res == 1 || error("Writing the SBML file \"$(fn)\" failed")
    finally
        ccall(sbml(:SBMLDocument_free), Cvoid, (VPtr,), doc)
    end
    return nothing
end

function writeSBML(mdl::Model)::String
    doc = _create_doc(mdl)
    str = try
        model_to_sbml!(doc, mdl)
        unsafe_string(ccall(sbml(:writeSBMLToString), Cstring, (VPtr,), doc))
    finally
        ccall(sbml(:SBMLDocument_free), Cvoid, (VPtr,), doc)
    end
    return str
end
