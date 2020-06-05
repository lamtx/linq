import "context.dart";
import "expression.dart";
import "named_expressible.dart";

abstract class NamedExpression<T> implements Expression<T>, NamedExpressible {
    factory NamedExpression(String name, [Expression<T> base]) {
        return _NamedExpressionImpl(name, base);
    }
}

class _NamedExpressionImpl<T> implements NamedExpression<T> {
    _NamedExpressionImpl(this.name, [Expression<T> base]) : _base = base;

    final Expression<T> _base;

    @override
    final String name;

    @override
    List<Object> args() {
        return _base?.args() ?? const [];
    }

    @override
    String clause(Context context) {
        if (_base == null) {
            return name;
        }
        return "${_base.clause(context)} as $name";
    }
}

extension ExpressionToNamedExpression<T> on Expression<T> {
    NamedExpression<T> named(String name) {
        return _NamedExpressionImpl(name, this);
    }
}

NamedExpression<void> get none => NamedExpression<void>("1");

NamedExpression<void> get star => NamedExpression<void>("*");
