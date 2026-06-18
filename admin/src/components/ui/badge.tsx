import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
  {
    variants: {
      variant: {
        blue:   "bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400",
        orange: "bg-accent-50 dark:bg-orange-900/30 text-accent-600 dark:text-orange-400",
        gray:   "bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-slate-300",
        green:  "bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-400",
        red:    "bg-red-50 dark:bg-red-900/30 text-red-700 dark:text-red-400",
      },
    },
    defaultVariants: { variant: "gray" },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };
